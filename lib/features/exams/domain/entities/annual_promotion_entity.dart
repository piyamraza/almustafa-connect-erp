import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../students/domain/entities/student_entity.dart';
import 'exam_result_entity.dart';

enum AnnualPromotionAction { promote, retain, graduate, noAction }

enum AnnualPromotionResultStatus { passed, failed, incomplete, noResult }

class AnnualPromotionPreviewItem {
  AnnualPromotionPreviewItem({
    required this.student,
    required this.result,
    required this.resultStatus,
    required this.action,
    required this.previousClassId,
    required this.previousSectionId,
    this.targetClassId,
    this.targetSectionId,
    this.warning = '',
    this.alreadyProcessed = false,
  });

  final StudentEntity student;
  final ExamResultEntity? result;
  final AnnualPromotionResultStatus resultStatus;
  AnnualPromotionAction action;
  final String previousClassId;
  final String previousSectionId;
  String? targetClassId;
  String? targetSectionId;
  String warning;
  final bool alreadyProcessed;

  bool get canProcess =>
      !alreadyProcessed && action != AnnualPromotionAction.noAction;
}

class AnnualPromotionPreview {
  const AnnualPromotionPreview({
    required this.fromSession,
    required this.toSession,
    required this.examId,
    required this.examName,
    required this.classes,
    required this.sections,
    required this.items,
  });

  final String fromSession;
  final String toSession;
  final String examId;
  final String examName;
  final List<AcademicClassEntity> classes;
  final List<SectionEntity> sections;
  final List<AnnualPromotionPreviewItem> items;
}

class AnnualPromotionExecutionSummary {
  const AnnualPromotionExecutionSummary({
    required this.runId,
    required this.promoted,
    required this.retained,
    required this.graduated,
    required this.noAction,
    required this.alreadyProcessed,
  });

  final String runId;
  final int promoted;
  final int retained;
  final int graduated;
  final int noAction;
  final int alreadyProcessed;
}
