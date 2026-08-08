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
    required ExamRepository examRepository,
    required ExamResultRepository resultRepository,
    required StudentRepository studentRepository,
    required AcademicStructureRepository structureRepository,
    required AcademicYearConfigRepository sessionRepository,
    required AnnualPromotionRepository promotionRepository,
  }) : _examRepository = examRepository,
       _resultRepository = resultRepository,
       _studentRepository = studentRepository,
       _structureRepository = structureRepository,
       _sessionRepository = sessionRepository,
       _promotionRepository = promotionRepository;

  final ExamRepository _examRepository;
  final ExamResultRepository _resultRepository;
  final StudentRepository _studentRepository;
  final AcademicStructureRepository _structureRepository;
  final AcademicYearConfigRepository _sessionRepository;
  final AnnualPromotionRepository _promotionRepository;

  Future<List<String>> sessions() async => (await _sessionRepository.getAll())
      .map((item) => item.academicSession)
      .toList(growable: false);

  Future<List<ExamEntity>> finalExams(String session) async =>
      (await _examRepository.getExams(academicSession: session))
          .where((exam) => exam.type == ExamType.finalExam)
          .toList(growable: false);

  Future<AnnualPromotionPreview> preview({
    required String academicSession,
    required String finalExamId,
  }) async {
    final sessions = await _sessionRepository.getAll();
    final fromIndex = sessions.indexWhere(
      (item) => item.academicSession == academicSession,
    );
    if (fromIndex < 0 || fromIndex + 1 >= sessions.length) {
      throw StateError(
        'The next academic session does not exist. Create it first.',
      );
    }

    final exam = await _examRepository.getExamById(finalExamId);
    if (exam == null ||
        exam.type != ExamType.finalExam ||
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

    final items = <AnnualPromotionPreviewItem>[];
    for (final student in students) {
      if (!student.isActive) continue;
      final classIndex = classes.indexWhere(
        (item) => item.id == student.classId,
      );
      if (classIndex < 0) continue;
      final candidateResult = resultsByStudent[student.id];
      final result =
          candidateResult?.classId == student.classId &&
              candidateResult?.academicSession == academicSession
          ? candidateResult
          : null;
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
        targetClassId = student.classId;
        targetSectionId = student.sectionId;
      } else {
        warning = resultStatus == AnnualPromotionResultStatus.incomplete
            ? 'Result incomplete / No action'
            : 'No final result / No action';
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
      toSession: sessions[fromIndex + 1].academicSession,
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
        .where((item) => item.id == previousSectionId)
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
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
