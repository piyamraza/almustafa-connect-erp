import '../entities/annual_promotion_entity.dart';

abstract class AnnualPromotionRepository {
  Future<Set<String>> processedStudentIds({
    required String academicSession,
    required String finalExamId,
  });

  Future<AnnualPromotionExecutionSummary> execute({
    required AnnualPromotionPreview preview,
  });
}
