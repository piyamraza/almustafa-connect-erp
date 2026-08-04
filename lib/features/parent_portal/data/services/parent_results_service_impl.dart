import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/domain/repositories/exam_result_repository.dart';
import '../../domain/entities/parent_results_summary.dart';
import '../../domain/services/parent_results_service.dart';

class ParentResultsServiceImpl implements ParentResultsService {
  const ParentResultsServiceImpl(this._repository);

  final ExamResultRepository _repository;

  @override
  Future<ParentResultsSummary> loadPublishedResults({
    required String studentId,
    String? examId,
    String? classId,
    String? sectionId,
  }) async {
    final values = await _repository.getPublishedResults(
      studentId: studentId.trim(),
      examId: examId,
      classId: classId,
      sectionId: sectionId,
    );

    final results = values.where((result) => result.isVisibleToParent).toList()
      ..sort((a, b) {
        final first = a.publishedAt ?? a.updatedAt;
        final second = b.publishedAt ?? b.updatedAt;
        return second.compareTo(first);
      });

    final total = results.length;
    final passed = results.where((result) => result.isPassed).length;
    final failed = total - passed;

    final average = total == 0
        ? 0.0
        : results
                  .map((result) => result.percentage)
                  .fold<double>(0, (sum, value) => sum + value) /
              total;

    return ParentResultsSummary(
      results: List<ExamResultEntity>.unmodifiable(results),
      latestResult: results.isEmpty ? null : results.first,
      totalPublishedResults: total,
      averagePercentage: average,
      passedResults: passed,
      failedResults: failed,
    );
  }
}
