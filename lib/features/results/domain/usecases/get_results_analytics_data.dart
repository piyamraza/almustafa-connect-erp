import '../../../exams/domain/entities/exam_subject_setup_entity.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/domain/usecases/get_exam_subject_setups.dart';
import '../entities/result_analytics_entity.dart';
import 'get_published_results.dart';

/// Loads the two existing, read-only data sources required by Results analytics.
/// Marks and calculated result records are never modified by this use case.
class GetResultsAnalyticsData {
  const GetResultsAnalyticsData({
    required GetPublishedResults getPublishedResults,
    required GetExamSubjectSetups getSubjectSetups,
  })  : _getPublishedResults = getPublishedResults,
        _getSubjectSetups = getSubjectSetups;

  final GetPublishedResults _getPublishedResults;
  final GetExamSubjectSetups _getSubjectSetups;

  Future<ResultAnalyticsData> call() async {
    final values = await Future.wait<Object>([
      _getPublishedResults(),
      _getSubjectSetups(),
    ]);
    return ResultAnalyticsData(
      results: values[0] as List<ExamResultEntity>,
      subjectSetups: values[1] as List<ExamSubjectSetupEntity>,
    );
  }
}
