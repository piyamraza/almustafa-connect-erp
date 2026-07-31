import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../domain/entities/result_export_request.dart';
import '../bloc/results_state.dart';

class ResultExportRequestFactory {
  const ResultExportRequestFactory._();

  static ResultExportRequest fromPublishedResults({
    required ResultExportType type,
    required String title,
    required List<ExamResultEntity> results,
    required PublishedResultsLoaded data,
    List<ResultExportMetric> metrics = const [],
    String? subjectName,
  }) {
    return ResultExportRequest(
      type: type,
      title: title,
      results: results,
      metrics: metrics,
      subjectName: subjectName,
      filters: {
        'Academic Session': data.selectedAcademicSession ?? '',
        'Exam': _labelFor(
          data.availableExams,
          data.selectedExamId,
          (item) => item.examId,
          (item) => item.examName,
        ),
        'Class': _labelFor(
          data.availableClasses,
          data.selectedClassId,
          (item) => item.classId,
          (item) => item.className,
        ),
        'Section': _labelFor(
          data.availableSections,
          data.selectedSectionId,
          (item) => item.sectionId,
          (item) => item.sectionName,
        ),
      },
    );
  }

  static ResultExportRequest fromArchive({
    required String title,
    required List<ExamResultEntity> results,
    required Map<String, String> filters,
    ResultExportType type = ResultExportType.gazette,
    List<ResultExportMetric> metrics = const [],
  }) {
    return ResultExportRequest(
      type: type,
      title: title,
      results: results,
      filters: filters,
      metrics: metrics,
    );
  }

  static List<ResultExportMetric> summaryMetrics(
    List<ExamResultEntity> results,
  ) {
    final passed = results.where((item) => item.isPassed).length;
    final average = results.isEmpty
        ? 0.0
        : results.fold<double>(0, (sum, item) => sum + item.percentage) /
              results.length;
    return [
      ResultExportMetric(label: 'Total Students', value: '${results.length}'),
      ResultExportMetric(label: 'Passed', value: '$passed'),
      ResultExportMetric(label: 'Failed', value: '${results.length - passed}'),
      ResultExportMetric(
        label: 'Pass Percentage',
        value:
            '${results.isEmpty ? 0 : ((passed / results.length) * 100).toStringAsFixed(1)}%',
      ),
      ResultExportMetric(
        label: 'Average Percentage',
        value: '${average.toStringAsFixed(1)}%',
      ),
    ];
  }

  static String _labelFor(
    List<ExamResultEntity> values,
    String? selectedId,
    String Function(ExamResultEntity) id,
    String Function(ExamResultEntity) label,
  ) {
    if (selectedId == null) return '';
    for (final value in values) {
      if (id(value) == selectedId) return label(value);
    }
    return '';
  }
}
