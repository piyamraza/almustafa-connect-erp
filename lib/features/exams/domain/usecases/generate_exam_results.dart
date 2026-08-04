import '../../../academic_structure/domain/services/subject_component_exam_service.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_reference_resolver.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../entities/exam_entity.dart';
import '../entities/exam_mark_entity.dart';
import '../entities/exam_result_entity.dart';
import '../entities/exam_subject_setup_entity.dart';
import '../entities/grade_rule_entity.dart';
import '../repositories/exam_mark_repository.dart';
import '../repositories/exam_repository.dart';
import '../repositories/exam_result_repository.dart';
import '../repositories/exam_subject_setup_repository.dart';
import '../repositories/grading_rule_repository.dart';

class GenerateExamResults {
  const GenerateExamResults({
    required this._examRepository,
    required this._subjectSetupRepository,
    required this._markRepository,
    required this._studentRepository,
    required this._gradingRuleRepository,
    required this._resultRepository,
    required this.componentService,
    required this.academicStructureRepository,
  });

  final ExamRepository _examRepository;
  final ExamSubjectSetupRepository _subjectSetupRepository;
  final ExamMarkRepository _markRepository;
  final StudentRepository _studentRepository;
  final GradingRuleRepository _gradingRuleRepository;
  final ExamResultRepository _resultRepository;
  final SubjectComponentExamService componentService;
  final AcademicStructureRepository academicStructureRepository;

  Future<List<ExamResultEntity>> call(
    String examId, {
    required String classId,
    required String sectionId,
    String actorId = '',
  }) async {
    final normalizedExamId = examId.trim();
    final normalizedClassId = classId.trim();
    final normalizedSectionId = sectionId.trim();
    final normalizedActorId = actorId.trim();

    if (normalizedExamId.isEmpty) {
      throw ArgumentError.value(examId, 'examId', 'Exam ID cannot be empty.');
    }

    if (normalizedClassId.isEmpty) {
      throw ArgumentError.value(
        classId,
        'classId',
        'Class ID cannot be empty.',
      );
    }

    if (normalizedSectionId.isEmpty) {
      throw ArgumentError.value(
        sectionId,
        'sectionId',
        'Section ID cannot be empty.',
      );
    }

    final responses = await Future.wait<Object?>([
      _examRepository.getExamById(normalizedExamId),
      _subjectSetupRepository.getSetupsForExam(normalizedExamId),
      _markRepository.getMarksForExam(normalizedExamId),
      _gradingRuleRepository.getActiveRules(),
      _resultRepository.getResultsForExam(normalizedExamId),
      _studentRepository.getStudents(),
      academicStructureRepository.getClasses(),
      academicStructureRepository.getSections(),
    ]);

    final exam = responses[0] as ExamEntity?;

    final allSetups = responses[1] as List<ExamSubjectSetupEntity>;
    final allMarks = responses[2] as List<ExamMarkEntity>;
    final allResults = responses[4] as List<ExamResultEntity>;
    final allStudents = responses[5] as List<StudentEntity>;
    final resolver = AcademicReferenceResolver(
      classes: responses[6] as List<AcademicClassEntity>,
      sections: responses[7] as List<SectionEntity>,
    );
    final scope = resolver.resolve(
      classReference: normalizedClassId,
      sectionReference: normalizedSectionId,
    );
    final rawSetups = allSetups
        .where(
          (setup) =>
              setup.isActive &&
              scope.matches(
                classId: setup.classId,
                className: setup.className,
                sectionId: setup.sectionId,
                sectionName: setup.sectionName,
              ),
        )
        .toList(growable: false);
    final setupLocationKeys = {
      for (final setup in rawSetups) _groupKey(setup.classId, setup.sectionId),
    };
    final setups = await componentService.expandSetups(
      rawSetups
          .map(
            (setup) => setup.copyWith(
              classId: scope.classId,
              className: scope.className,
              sectionId: scope.sectionId,
              sectionName: scope.sectionName,
            ),
          )
          .toList(growable: false),
    );

    final marks = allMarks
        .where(
          (mark) =>
              setupLocationKeys.contains(
                _groupKey(mark.classId, mark.sectionId),
              ) ||
              scope.matches(classId: mark.classId, sectionId: mark.sectionId),
        )
        .toList(growable: false);

    final rules = (responses[3] as List<GradeRuleEntity>)
        .where((rule) => rule.isActive)
        .toList(growable: false);

    final existingResults = allResults
        .where(
          (result) => scope.matches(
            classId: result.classId,
            className: result.className,
            sectionId: result.sectionId,
            sectionName: result.sectionName,
          ),
        )
        .toList(growable: false);

    final students = allStudents
        .where(
          (student) =>
              student.isActive &&
              scope.matches(
                classId: student.classId,
                sectionId: student.sectionId,
              ),
        )
        .toList(growable: false);

    if (exam == null) {
      throw StateError('The selected exam no longer exists.');
    }

    if (setups.isEmpty) {
      throw StateError(
        'No subject setup is configured for the selected class and section.',
      );
    }

    if (students.isEmpty) {
      throw StateError(
        'No students are enrolled in the selected class and section. '
        'If students exist, their class/section references do not match the academic structure.',
      );
    }

    if (rules.isEmpty) {
      throw StateError(
        'Configure at least one active grade rule before generating results.',
      );
    }

    if (existingResults.any((result) => result.status == ResultStatus.locked)) {
      throw StateError('Locked results cannot be regenerated.');
    }

    if (existingResults.any(
      (result) =>
          result.status == ResultStatus.published ||
          result.status == ResultStatus.approved,
    )) {
      throw StateError(
        'Approved or published results cannot be regenerated. '
        'Move them back to an editable workflow status first.',
      );
    }

    final rulesByMinimum = [...rules]
      ..sort(
        (first, second) =>
            second.minimumPercentage.compareTo(first.minimumPercentage),
      );

    _validateGradeRules(rulesByMinimum);

    final existingByStudentId = {
      for (final result in existingResults) result.studentId: result,
    };

    final markByIdentity = <String, ExamMarkEntity>{};

    for (final mark in marks) {
      final identity = _markIdentity(
        subjectId: mark.subjectId,
        studentId: mark.studentId,
      );

      if (markByIdentity.containsKey(identity)) {
        throw StateError(
          'Duplicate marks exist for the same student and subject.',
        );
      }

      markByIdentity[identity] = mark;
    }

    final setupsBySubject = <String, ExamSubjectSetupEntity>{};
    for (final setup in setups) {
      if (setupsBySubject.containsKey(setup.subjectId)) {
        throw StateError(
          'Duplicate subject setup exists for ${setup.subjectName} in '
          '${scope.className}-${scope.sectionName}.',
        );
      }
      setupsBySubject[setup.subjectId] = setup;
    }

    final now = DateTime.now();
    final generated = <ExamResultEntity>[];

    final groupSetups = setupsBySubject.values.toList(growable: false);
    for (final student in students) {
      generated.add(
        _buildResult(
          exam: exam,
          student: student,
          setups: groupSetups,
          markByIdentity: markByIdentity,
          gradeRules: rulesByMinimum,
          existingResult: existingByStudentId[student.id],
          generatedAt: now,
          generatedBy: normalizedActorId,
        ),
      );
    }

    final ranked = _applyRanks(generated);

    await _resultRepository.saveResults(ranked);

    return ranked;
  }

  ExamResultEntity _buildResult({
    required ExamEntity exam,
    required StudentEntity student,
    required List<ExamSubjectSetupEntity> setups,
    required Map<String, ExamMarkEntity> markByIdentity,
    required List<GradeRuleEntity> gradeRules,
    required ExamResultEntity? existingResult,
    required DateTime generatedAt,
    required String generatedBy,
  }) {
    final subjectResults = <SubjectResultEntity>[];

    for (final setup in setups) {
      final mark =
          markByIdentity[_markIdentity(
            subjectId: setup.subjectId,
            studentId: student.id,
          )];

      if (mark == null) {
        throw StateError(
          'Marks are missing for ${student.fullName} '
          'in ${setup.subjectName}.',
        );
      }

      if (mark.obtainedMarks < 0 || mark.obtainedMarks > setup.totalMarks) {
        throw StateError(
          'Invalid marks for ${student.fullName} '
          'in ${setup.subjectName}.',
        );
      }

      if (mark.isAbsent && mark.obtainedMarks != 0) {
        throw StateError(
          'Absent student ${student.fullName} must '
          'have zero marks in ${setup.subjectName}.',
        );
      }

      subjectResults.add(
        SubjectResultEntity(
          subjectId: setup.subjectId,
          subjectName: setup.subjectName,
          totalMarks: setup.totalMarks,
          obtainedMarks: mark.obtainedMarks,
          isAbsent: mark.isAbsent,
          isPassed: !mark.isAbsent && mark.obtainedMarks >= setup.passingMarks,
          remarks: mark.remarks,
        ),
      );
    }

    final grandTotal = subjectResults.fold<double>(
      0,
      (total, subject) => total + subject.totalMarks,
    );

    final grandObtained = subjectResults.fold<double>(
      0,
      (total, subject) => total + subject.obtainedMarks,
    );

    final percentage = grandTotal == 0
        ? 0.0
        : (grandObtained / grandTotal) * 100;

    GradeRuleEntity? gradeRule;

    for (final rule in gradeRules) {
      if (rule.includes(percentage)) {
        gradeRule = rule;
        break;
      }
    }

    if (gradeRule == null) {
      throw StateError(
        'No grade rule covers '
        '${percentage.toStringAsFixed(2)}%.',
      );
    }

    final firstSetup = setups.first;

    return ExamResultEntity(
      id: ExamResultEntity.documentIdFor(
        examId: exam.id,
        classId: firstSetup.classId,
        sectionId: firstSetup.sectionId,
        studentId: student.id,
      ),
      examId: exam.id,
      examName: exam.name,
      academicSession: exam.academicSession,
      classId: firstSetup.classId,
      className: firstSetup.className,
      sectionId: firstSetup.sectionId,
      sectionName: firstSetup.sectionName,
      studentId: student.id,
      studentName: student.fullName.trim(),
      rollNumber: student.rollNumber,
      admissionNo: student.admissionNo,
      subjectResults: subjectResults,
      grandTotalMarks: grandTotal,
      grandObtainedMarks: grandObtained,
      percentage: percentage,
      grade: gradeRule.grade,
      isPassed:
          subjectResults.every((subject) => subject.isPassed) &&
          gradeRule.isPassing,
      classPosition: 0,
      sectionPosition: 0,
      overallRank: 0,
      status: ResultStatus.generated,
      createdAt: existingResult?.createdAt ?? generatedAt,
      updatedAt: generatedAt,
      generatedAt: generatedAt,
      generatedBy: generatedBy.isNotEmpty
          ? generatedBy
          : existingResult?.generatedBy ?? '',
      verifiedAt: null,
      verifiedBy: '',
      approvedAt: null,
      approvedBy: '',
      publishedAt: null,
      publishedBy: '',
      lockedAt: null,
      lockedBy: '',
      unlockedAt: existingResult?.unlockedAt,
      unlockedBy: existingResult?.unlockedBy ?? '',
      unlockReason: existingResult?.unlockReason ?? '',
      principalRemarks: existingResult?.principalRemarks ?? '',
    );
  }

  List<ExamResultEntity> _applyRanks(List<ExamResultEntity> results) {
    final sectionRanks = _rankBy(
      results,
      (result) => _groupKey(result.classId, result.sectionId),
    );

    final classRanks = _rankBy(results, (result) => result.classId);

    final overallRanks = _rankSingleGroup(results);

    return results
        .map(
          (result) => result.copyWith(
            sectionPosition: sectionRanks[result.id] ?? 0,
            classPosition: classRanks[result.id] ?? 0,
            overallRank: overallRanks[result.id] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Map<String, int> _rankBy(
    List<ExamResultEntity> results,
    String Function(ExamResultEntity result) groupSelector,
  ) {
    final groups = <String, List<ExamResultEntity>>{};

    for (final result in results) {
      (groups[groupSelector(result)] ??= []).add(result);
    }

    final ranks = <String, int>{};

    for (final group in groups.values) {
      ranks.addAll(_rankSingleGroup(group));
    }

    return ranks;
  }

  Map<String, int> _rankSingleGroup(List<ExamResultEntity> results) {
    final sorted = [...results]..sort(_compareForRank);

    final ranks = <String, int>{};

    double? previousPercentage;
    double? previousObtained;
    var currentRank = 0;

    for (var index = 0; index < sorted.length; index++) {
      final result = sorted[index];

      final isTie =
          previousPercentage != null &&
          previousObtained != null &&
          result.percentage == previousPercentage &&
          result.grandObtainedMarks == previousObtained;

      if (!isTie) {
        currentRank = index + 1;
      }

      ranks[result.id] = currentRank;
      previousPercentage = result.percentage;
      previousObtained = result.grandObtainedMarks;
    }

    return ranks;
  }

  int _compareForRank(ExamResultEntity first, ExamResultEntity second) {
    final percentage = second.percentage.compareTo(first.percentage);

    if (percentage != 0) {
      return percentage;
    }

    final obtained = second.grandObtainedMarks.compareTo(
      first.grandObtainedMarks,
    );

    if (obtained != 0) {
      return obtained;
    }

    return first.studentName.toLowerCase().compareTo(
      second.studentName.toLowerCase(),
    );
  }

  void _validateGradeRules(List<GradeRuleEntity> rules) {
    for (var index = 0; index < rules.length; index++) {
      final rule = rules[index];

      if (rule.minimumPercentage < 0 ||
          rule.maximumPercentage > 100 ||
          rule.minimumPercentage > rule.maximumPercentage) {
        throw StateError(
          'Grade rule ${rule.grade} has '
          'an invalid percentage range.',
        );
      }

      if (index > 0 &&
          rule.maximumPercentage >= rules[index - 1].minimumPercentage) {
        throw StateError(
          'Grade rule ${rule.grade} overlaps '
          'another grade rule.',
        );
      }
    }
  }

  String _groupKey(String classId, String sectionId) {
    return '$classId|$sectionId';
  }

  String _markIdentity({required String subjectId, required String studentId}) {
    return '$subjectId|$studentId';
  }
}
