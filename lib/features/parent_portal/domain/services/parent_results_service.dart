import '../entities/parent_results_summary.dart';

abstract class ParentResultsService {
  Future<ParentResultsSummary> loadPublishedResults({
    required String studentId,
    String? examId,
    String? classId,
    String? sectionId,
  });
}
