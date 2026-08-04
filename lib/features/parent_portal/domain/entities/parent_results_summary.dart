import '../../../exams/domain/entities/exam_result_entity.dart';

class ParentResultsSummary {
  const ParentResultsSummary({
    required this.results,
    required this.latestResult,
    required this.totalPublishedResults,
    required this.averagePercentage,
    required this.passedResults,
    required this.failedResults,
  });

  final List<ExamResultEntity> results;
  final ExamResultEntity? latestResult;
  final int totalPublishedResults;
  final double averagePercentage;
  final int passedResults;
  final int failedResults;
}
