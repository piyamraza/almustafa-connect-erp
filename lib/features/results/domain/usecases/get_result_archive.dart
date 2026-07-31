import '../../../exams/domain/entities/exam_result_entity.dart';
import 'get_published_results.dart';

/// Historical archive boundary. Published and locked examination results remain
/// the single source of truth; this use case never copies or mutates them.
class GetResultArchive {
  const GetResultArchive(this._getPublishedResults);

  final GetPublishedResults _getPublishedResults;

  Future<List<ExamResultEntity>> call() => _getPublishedResults();
}
