import '../../../academic_calendar/domain/entities/academic_year_config_entity.dart';
import '../../../academic_calendar/domain/repositories/academic_year_config_repository.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../entities/annual_promotion_entity.dart';
import '../entities/exam_entity.dart';
import '../entities/exam_result_entity.dart';
import '../repositories/annual_promotion_repository.dart';
import '../repositories/exam_repository.dart';
import '../repositories/exam_result_repository.dart';

class AnnualPromotionService {
  const AnnualPromotionService({
    required this._examRepository,
    required this._resultRepository,
    required this._studentRepository,
    required this._structureRepository,
    required this._sessionRepository,
    required this._promotionRepository,
  });

  final ExamRepository _examRepository;
  final ExamResultRepository _resultRepository;
  final StudentRepository _studentRepository;
  final AcademicStructureRepository _structureRepository;
  final AcademicYearConfigRepository _sessionRepository;
  final AnnualPromotionRepository _promotionRepository;

  Future<List<String>> sessions() async {
    final values = await Future.wait<Object>([
      _sessionRepository.getAll(),
      _examRepository.getExams(),
    ]);
    final sessions = <String>{
      for (final item in values[0] as List<AcademicYearConfigEntity>)
        if (item.academicSession.trim().isNotEmpty) item.academicSession.trim(),
      for (final exam in values[1] as List<ExamEntity>)
        if (_isFinalExam(exam) && exam.academicSession.trim().isNotEmpty)
          exam.academicSession.trim(),
    }.toList()..sort(_compareSessions);
    return List.unmodifiable(sessions);
  }

  Future<List<ExamEntity>> finalExams(String session) async =>
      (await _examRepository.getExams(
        academicSession: session,
      )).where(_isFinalExam).toList(growable: false);

  Future<AnnualPromotionPreview> preview({
    required String academicSession,
    required String finalExamId,
  }) async {
    final sessions = await _sessionRepository.getAll();
    final fromIndex = sessions.indexWhere(
      (item) => item.academicSession == academicSession,
    );
    final toSession = fromIndex >= 0 && fromIndex + 1 < sessions.length
        ? sessions[fromIndex + 1].academicSession
        : _nextSession(academicSession);

    final exam = await _examRepository.getExamById(finalExamId);
    if (exam == null ||
        !_isFinalExam(exam) ||
        exam.academicSession != academicSession) {
      throw StateError('Select a valid Final Exam for this academic session.');
    }

    final values = await Future.wait<Object>([
      _studentRepository.getStudents(),
      _structureRepository.getClasses(),
      _structureRepository.getSections(),
      _resultRepository.getResultsForExam(finalExamId),
      _promotionRepository.processedStudentIds(
        academicSession: academicSession,
        finalExamId: finalExamId,
      ),
    ]);
    final students = values[0] as List<StudentEntity>;
    final classes = (values[1] as List<AcademicClassEntity>)
        .where((item) => item.isActive)
        .toList();
    final sections = (values[2] as List<SectionEntity>)
        .where((item) => item.isActive)
        .toList();
    final results = values[3] as List<ExamResultEntity>;
    final processed = values[4] as Set<String>;
    classes.sort(_compareClasses);
    final resultsByStudent = {
      for (final result in results) result.studentId: result,
    };
    final resultsByAdmission = {
      for (final result in results)
        if (result.admissionNo.trim().isNotEmpty)
          _normalize(result.admissionNo): result,
    };

    final items = <AnnualPromotionPreviewItem>[];
    for (final student in students) {
      if (!student.isActive) continue;
      final classIndex = classes.indexWhere(
        (item) => _matchesIdOrName(student.classId, item.id, item.name),
      );
      if (classIndex < 0) continue;
      final currentClass = classes[classIndex];
      final candidateResult =
          resultsByStudent[student.id] ??
          resultsByAdmission[_normalize(student.admissionNo)];
      final result = candidateResult?.academicSession == academicSession
          ? candidateResult
          : null;
      final resultClassMismatch =
          result != null &&
          !_matchesIdOrName(result.classId, currentClass.id, currentClass.name);
      final resultStatus = _resultStatus(result);
      var action = AnnualPromotionAction.noAction;
      String? targetClassId;
      String? targetSectionId;
      var warning = '';
      if (resultStatus == AnnualPromotionResultStatus.passed) {
        if (classIndex == classes.length - 1) {
          action = AnnualPromotionAction.graduate;
        } else {
          action = AnnualPromotionAction.promote;
          targetClassId = classes[classIndex + 1].id;
          targetSectionId = _matchingSection(
            previousSectionId: student.sectionId,
            targetClassId: targetClassId,
            sections: sections,
          );
          if (targetSectionId == null &&
              sections
                  .where((item) => item.classId == targetClassId)
                  .isNotEmpty) {
            warning = 'Select a target section.';
          }
        }
      } else if (resultStatus == AnnualPromotionResultStatus.failed) {
        action = AnnualPromotionAction.retain;
        targetClassId = currentClass.id;
        targetSectionId = _canonicalSectionId(
          value: student.sectionId,
          classId: currentClass.id,
          sections: sections,
        );
      } else {
        warning = resultStatus == AnnualPromotionResultStatus.incomplete
            ? 'Result incomplete / No action'
            : 'No final result / No action';
      }
      if (resultClassMismatch) {
        action = AnnualPromotionAction.noAction;
        targetClassId = null;
        targetSectionId = null;
        warning =
            'Student current class (${currentClass.name}) differs from final result class (${result.className}). Correct the student class first.';
      }
      final wasProcessed = processed.contains(student.id);
      items.add(
        AnnualPromotionPreviewItem(
          student: student,
          result: result,
          resultStatus: resultStatus,
          action: wasProcessed ? AnnualPromotionAction.noAction : action,
          previousClassId: student.classId,
          previousSectionId: student.sectionId,
          targetClassId: targetClassId,
          targetSectionId: targetSectionId,
          warning: wasProcessed
              ? 'Already processed for this Final Exam.'
              : warning,
          alreadyProcessed: wasProcessed,
        ),
      );
    }

    return AnnualPromotionPreview(
      fromSession: academicSession,
      toSession: toSession,
      examId: exam.id,
      examName: exam.name,
      classes: classes,
      sections: sections,
      items: items,
    );
  }

  Future<AnnualPromotionExecutionSummary> execute(
    AnnualPromotionPreview preview,
  ) => _promotionRepository.execute(preview: preview);

  AnnualPromotionResultStatus _resultStatus(ExamResultEntity? result) {
    if (result == null) return AnnualPromotionResultStatus.noResult;
    if (!result.isPublished || result.subjectResults.isEmpty) {
      return AnnualPromotionResultStatus.incomplete;
    }
    return result.isPassed
        ? AnnualPromotionResultStatus.passed
        : AnnualPromotionResultStatus.failed;
  }

  String? _matchingSection({
    required String previousSectionId,
    required String targetClassId,
    required List<SectionEntity> sections,
  }) {
    final previous = sections
        .where(
          (item) => _matchesIdOrName(previousSectionId, item.id, item.name),
        )
        .firstOrNull;
    final targetSections = sections
        .where((item) => item.classId == targetClassId)
        .toList();
    if (targetSections.isEmpty) return '';
    if (targetSections.length == 1) return targetSections.single.id;
    if (previous == null) return null;
    return targetSections
        .where(
          (item) =>
              item.name.trim().toLowerCase() ==
              previous.name.trim().toLowerCase(),
        )
        .firstOrNull
        ?.id;
  }

  String? _canonicalSectionId({
    required String value,
    required String classId,
    required List<SectionEntity> sections,
  }) {
    if (value.trim().isEmpty) return '';
    return sections
        .where(
          (item) =>
              item.classId == classId &&
              _matchesIdOrName(value, item.id, item.name),
        )
        .firstOrNull
        ?.id;
  }

  int _compareClasses(AcademicClassEntity a, AcademicClassEntity b) {
    final aOrder = _naturalOrder(a.name);
    final bOrder = _naturalOrder(b.name);
    final compared = aOrder.compareTo(bOrder);
    return compared != 0 ? compared : a.createdAt.compareTo(b.createdAt);
  }

  int _naturalOrder(String name) {
    final value = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    const early = {'playgroup': -30, 'nursery': -20, 'prep': -10, 'kg': -10};
    if (early.containsKey(value)) return early[value]!;
    final number = int.tryParse(
      RegExp(r'\d+').firstMatch(value)?.group(0) ?? '',
    );
    return number ?? 100000;
  }

  bool _isFinalExam(ExamEntity exam) {
    if (exam.type == ExamType.finalExam) return true;
    final name = exam.name.trim().toLowerCase();
    return name.contains('final') || name.contains('annual');
  }

  int _compareSessions(String first, String second) {
    int startYear(String value) =>
        int.tryParse(RegExp(r'\d{4}').firstMatch(value)?.group(0) ?? '') ?? 0;
    final compared = startYear(first).compareTo(startYear(second));
    return compared != 0 ? compared : first.compareTo(second);
  }

  bool _matchesIdOrName(String value, String id, String name) {
    final normalized = _normalize(value);
    return normalized == _normalize(id) || normalized == _normalize(name);
  }

  String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  String _nextSession(String session) {
    final years = RegExp(
      r'\d{4}',
    ).allMatches(session).map((m) => m.group(0)!).toList();
    if (years.length >= 2) {
      final start = int.parse(years[0]);
      final end = int.parse(years[1]);
      return '${start + 1}-${end + 1}';
    }
    throw StateError(
      'The next academic session could not be determined from $session.',
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
