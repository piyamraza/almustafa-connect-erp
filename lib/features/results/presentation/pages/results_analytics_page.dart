import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../domain/entities/result_export_request.dart';
import '../../domain/entities/result_analytics_entity.dart';
import '../../domain/usecases/results_analytics_calculator.dart';
import '../bloc/results_analytics_bloc.dart';
import '../bloc/results_analytics_event.dart';
import '../bloc/results_analytics_state.dart';
import '../widgets/results_analytics_charts.dart';
import '../widgets/results_analytics_filter_card.dart';
import '../widgets/results_export_actions.dart';

enum ResultsAnalyticsView {
  overview,
  subject,
  student,
  classPerformance,
  sectionComparison,
  passFail,
  topAndWeak,
}

class ResultsAnalyticsPage extends StatelessWidget {
  const ResultsAnalyticsPage({required this.view, super.key});

  final ResultsAnalyticsView view;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ResultsAnalyticsBloc>()..add(const LoadResultsAnalytics()),
      child: _ResultsAnalyticsView(view: view),
    );
  }
}

class _ResultsAnalyticsView extends StatelessWidget {
  const _ResultsAnalyticsView({required this.view});

  final ResultsAnalyticsView view;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title(view)),
        actions: [const DashboardNavigationButton(),
          IconButton(
            tooltip: 'Refresh published results',
            onPressed: () => context.read<ResultsAnalyticsBloc>().add(
              const RefreshResultsAnalytics(),
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<ResultsAnalyticsBloc, ResultsAnalyticsState>(
        builder: (context, state) {
          if (state is ResultsAnalyticsInitial ||
              state is ResultsAnalyticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ResultsAnalyticsFailure) {
            return _AnalyticsFailure(message: state.message);
          }
          return _AnalyticsContent(
            view: view,
            data: state as ResultsAnalyticsLoaded,
          );
        },
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.view, required this.data});

  final ResultsAnalyticsView view;
  final ResultsAnalyticsLoaded data;

  @override
  Widget build(BuildContext context) {
    final content = switch (view) {
      ResultsAnalyticsView.overview => _OverallAnalytics(data: data),
      ResultsAnalyticsView.subject => _SubjectAnalytics(data: data),
      ResultsAnalyticsView.student => _StudentAnalytics(data: data),
      ResultsAnalyticsView.classPerformance => _ClassAnalytics(data: data),
      ResultsAnalyticsView.sectionComparison => _SectionAnalytics(data: data),
      ResultsAnalyticsView.passFail => _PassFailAnalytics(data: data),
      ResultsAnalyticsView.topAndWeak => _TopWeakAnalytics(data: data),
    };
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.isRefreshing) const LinearProgressIndicator(),
                if (data.isRefreshing) const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ResultsExportActions(
                    request: ResultExportRequest(
                      type: _exportType(view),
                      title: _title(view),
                      results: data.results,
                      subjectName: data.filter.subjectName,
                      filters: {
                        'Academic Session': data.filter.academicSession ?? '',
                        'Subject': data.filter.subjectName ?? '',
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

ResultExportType _exportType(ResultsAnalyticsView view) => switch (view) {
  ResultsAnalyticsView.overview => ResultExportType.overallStatistics,
  ResultsAnalyticsView.subject => ResultExportType.subjectAnalysis,
  ResultsAnalyticsView.student => ResultExportType.studentPerformance,
  ResultsAnalyticsView.classPerformance => ResultExportType.classPerformance,
  ResultsAnalyticsView.sectionComparison => ResultExportType.classPerformance,
  ResultsAnalyticsView.passFail => ResultExportType.passFail,
  ResultsAnalyticsView.topAndWeak => ResultExportType.topStudents,
};

class _OverallAnalytics extends StatelessWidget {
  const _OverallAnalytics({required this.data});

  final ResultsAnalyticsLoaded data;

  @override
  Widget build(BuildContext context) {
    final overview = ResultsAnalyticsCalculator.overview(
      data.data,
      data.filter,
    );
    final classSummaries = ResultsAnalyticsCalculator.classSummaries(
      data.data,
      data.filter,
    );
    final subjectSummaries = ResultsAnalyticsCalculator.subjectPerformances(
      data.data,
      data.filter,
    );
    final passFail = [
      ResultChartPoint(label: 'Pass', value: overview.passedResults.toDouble()),
      ResultChartPoint(label: 'Fail', value: overview.failedResults.toDouble()),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResultsAnalyticsFilterCard(data: data, showSection: false),
        const SizedBox(height: 18),
        _MetricWrap(
          metrics: [
            _Metric(
              'Published Results',
              '${overview.totalPublishedResults}',
              Icons.fact_check_outlined,
            ),
            _Metric(
              'Students Evaluated',
              '${overview.totalStudentsEvaluated}',
              Icons.groups_outlined,
            ),
            _Metric(
              'Pass Percentage',
              _percent(overview.passPercentage),
              Icons.check_circle_outline,
            ),
            _Metric(
              'Fail Percentage',
              _percent(overview.failPercentage),
              Icons.cancel_outlined,
            ),
            _Metric(
              'Average Percentage',
              _percent(overview.averagePercentage),
              Icons.analytics_outlined,
            ),
            _Metric(
              'Highest Percentage',
              _percent(overview.highestPercentage),
              Icons.arrow_upward,
            ),
            _Metric(
              'Lowest Percentage',
              _percent(overview.lowestPercentage),
              Icons.arrow_downward,
            ),
            _Metric(
              'Best Class',
              overview.bestClass?.name ?? '-',
              Icons.workspace_premium_outlined,
            ),
            _Metric(
              'Weakest Class',
              overview.weakestClass?.name ?? '-',
              Icons.trending_down_outlined,
            ),
            _Metric(
              'Best Subject',
              overview.bestSubject?.subjectName ?? '-',
              Icons.menu_book_outlined,
            ),
            _Metric(
              'Weakest Subject',
              overview.weakestSubject?.subjectName ?? '-',
              Icons.menu_book_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ChartGrid(
          children: [
            ResultsPieChart(title: 'Pass vs Fail', points: passFail),
            ResultsBarChart(
              title: 'Grade Distribution',
              points: ResultsAnalyticsCalculator.gradeDistribution(
                data.data,
                data.filter,
              ),
              maxY: 1,
              valueSuffix: '',
            ),
            ResultsBarChart(
              title: 'Subject Performance',
              points: subjectSummaries
                  .map(
                    (item) => ResultChartPoint(
                      label: item.subjectName,
                      value: item.averagePercentage,
                    ),
                  )
                  .toList(growable: false),
            ),
            ResultsBarChart(
              title: 'Class Comparison',
              points: classSummaries
                  .map(
                    (item) => ResultChartPoint(
                      label: item.name,
                      value: item.averagePercentage,
                    ),
                  )
                  .toList(growable: false),
            ),
            ResultsLineChart(
              title: 'Exam-wise Performance Trend',
              points: ResultsAnalyticsCalculator.examTrend(
                data.data,
                data.filter,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubjectAnalytics extends StatelessWidget {
  const _SubjectAnalytics({required this.data});

  final ResultsAnalyticsLoaded data;

  @override
  Widget build(BuildContext context) {
    final rows = ResultsAnalyticsCalculator.subjectRows(data.data, data.filter);
    final summary = ResultsAnalyticsCalculator.subjectSummary(rows);
    final subjectName = data.filter.subjectName ?? 'All Subjects';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResultsAnalyticsFilterCard(
          data: data,
          showSubject: true,
          showSearch: true,
          showSort: true,
        ),
        const SizedBox(height: 18),
        Text(
          subjectName,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _MetricWrap(
          metrics: [
            _Metric(
              'Total Students',
              '${summary.totalStudents}',
              Icons.groups_outlined,
            ),
            _Metric(
              'Appeared',
              '${summary.appearedStudents}',
              Icons.how_to_reg_outlined,
            ),
            _Metric(
              'Absent',
              '${summary.absentStudents}',
              Icons.person_off_outlined,
            ),
            _Metric(
              'Passed',
              '${summary.passedStudents}',
              Icons.check_circle_outline,
            ),
            _Metric(
              'Failed',
              '${summary.failedStudents}',
              Icons.cancel_outlined,
            ),
            _Metric(
              'Pass Percentage',
              _percent(summary.passPercentage),
              Icons.percent_outlined,
            ),
            _Metric(
              'Fail Percentage',
              _percent(summary.failPercentage),
              Icons.percent_outlined,
            ),
            _Metric(
              'Highest Marks',
              _number(summary.highestMarks),
              Icons.arrow_upward,
            ),
            _Metric(
              'Lowest Marks',
              _number(summary.lowestMarks),
              Icons.arrow_downward,
            ),
            _Metric(
              'Average Marks',
              _number(summary.averageMarks),
              Icons.analytics_outlined,
            ),
            _Metric(
              'Total Marks',
              _number(summary.totalMarks),
              Icons.score_outlined,
            ),
            _Metric(
              'Passing Marks',
              summary.passingMarks == null
                  ? '-'
                  : _number(summary.passingMarks!),
              Icons.flag_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SubjectRowsTable(rows: rows),
      ],
    );
  }
}

class _StudentAnalytics extends StatelessWidget {
  const _StudentAnalytics({required this.data});

  final ResultsAnalyticsLoaded data;

  @override
  Widget build(BuildContext context) {
    final summary = ResultsAnalyticsCalculator.studentPerformance(
      data.data,
      data.filter,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResultsAnalyticsFilterCard(data: data, showStudent: true),
        const SizedBox(height: 18),
        if (summary == null)
          const _EmptyAnalytics(
            message:
                'Select a student to view performance across published exams.',
          )
        else ...[
          _MetricWrap(
            metrics: [
              _Metric(
                'Average Percentage',
                _percent(summary.averagePercentage),
                Icons.analytics_outlined,
              ),
              _Metric(
                'Passed Exams',
                '${summary.passedExams}',
                Icons.check_circle_outline,
              ),
              _Metric(
                'Failed Exams',
                '${summary.failedExams}',
                Icons.cancel_outlined,
              ),
              _Metric(
                'Strong Subject',
                summary.strongestSubject?.subjectName ?? '-',
                Icons.thumb_up_outlined,
              ),
              _Metric(
                'Weak Subject',
                summary.weakestSubject?.subjectName ?? '-',
                Icons.flag_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ChartGrid(
            children: [
              ResultsLineChart(
                title: 'Student Percentage Trend',
                points: ResultsAnalyticsCalculator.studentTrend(summary),
              ),
              ResultsBarChart(
                title: 'Subject-wise Performance',
                points: summary.subjectPerformances
                    .map(
                      (item) => ResultChartPoint(
                        label: item.subjectName,
                        value: item.averagePercentage,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _StudentPerformanceTable(summary: summary),
        ],
      ],
    );
  }
}

class _ClassAnalytics extends StatelessWidget {
  const _ClassAnalytics({required this.data});

  final ResultsAnalyticsLoaded data;

  @override
  Widget build(BuildContext context) {
    final classes = ResultsAnalyticsCalculator.classSummaries(
      data.data,
      data.filter,
    );
    final selected = data.filter.classId == null || classes.isEmpty
        ? null
        : classes.first;
    final results = [...data.results]
      ..sort((first, second) {
        final position = first.classPosition.compareTo(second.classPosition);
        return position != 0
            ? position
            : second.percentage.compareTo(first.percentage);
      });
    final subjects = ResultsAnalyticsCalculator.subjectPerformances(
      data.data,
      data.filter,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResultsAnalyticsFilterCard(data: data, showSection: false),
        const SizedBox(height: 18),
        if (selected == null && data.filter.classId == null)
          _ClassComparisonList(items: classes)
        else if (selected == null)
          const _EmptyAnalytics(
            message: 'No published results were found for this class.',
          )
        else ...[
          _MetricWrap(
            metrics: [
              _Metric(
                'Total Students',
                '${selected.totalStudents}',
                Icons.groups_outlined,
              ),
              _Metric(
                'Passed',
                '${selected.passedStudents}',
                Icons.check_circle_outline,
              ),
              _Metric(
                'Failed',
                '${selected.failedStudents}',
                Icons.cancel_outlined,
              ),
              _Metric(
                'Pass Percentage',
                _percent(selected.passPercentage),
                Icons.percent_outlined,
              ),
              _Metric(
                'Class Average',
                _percent(selected.averagePercentage),
                Icons.analytics_outlined,
              ),
              _Metric(
                'Highest Percentage',
                _percent(selected.highestPercentage),
                Icons.arrow_upward,
              ),
              _Metric(
                'Lowest Percentage',
                _percent(selected.lowestPercentage),
                Icons.arrow_downward,
              ),
              _Metric(
                'Top Performer',
                selected.topPerformer?.studentName ?? '-',
                Icons.emoji_events_outlined,
              ),
              _Metric(
                'Weakest Performer',
                selected.weakestPerformer?.studentName ?? '-',
                Icons.trending_down_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ChartGrid(
            children: [
              ResultsBarChart(
                title: 'Subject-wise Class Average',
                points: subjects
                    .map(
                      (item) => ResultChartPoint(
                        label: item.subjectName,
                        value: item.averagePercentage,
                      ),
                    )
                    .toList(growable: false),
              ),
              ResultsBarChart(
                title: 'Subject-wise Pass Percentage',
                points: ResultsAnalyticsCalculator.subjectPassPercentages(
                  data.data,
                  data.filter,
                ),
              ),
              ResultsBarChart(
                title: 'Grade Distribution',
                points: ResultsAnalyticsCalculator.gradeDistribution(
                  data.data,
                  data.filter,
                ),
                maxY: 1,
                valueSuffix: '',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ClassRankingTable(results: results),
        ],
      ],
    );
  }
}

class _SectionAnalytics extends StatelessWidget {
  const _SectionAnalytics({required this.data});

  final ResultsAnalyticsLoaded data;

  @override
  Widget build(BuildContext context) {
    final sections = ResultsAnalyticsCalculator.sectionSummaries(
      data.data,
      data.filter,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResultsAnalyticsFilterCard(data: data, showSection: false),
        const SizedBox(height: 18),
        if (data.filter.classId == null)
          const _EmptyAnalytics(
            message: 'Select a class to compare its published-result sections.',
          )
        else if (sections.isEmpty)
          const _EmptyAnalytics(
            message: 'No published results were found for this class.',
          )
        else ...[
          _ChartGrid(
            children: [
              ResultsBarChart(
                title: 'Section Pass Percentage',
                points: sections
                    .map(
                      (item) => ResultChartPoint(
                        label: item.name,
                        value: item.passPercentage,
                      ),
                    )
                    .toList(growable: false),
              ),
              ResultsBarChart(
                title: 'Section Average Percentage',
                points: sections
                    .map(
                      (item) => ResultChartPoint(
                        label: item.name,
                        value: item.averagePercentage,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionComparisonTable(items: sections),
        ],
      ],
    );
  }
}

class _PassFailAnalytics extends StatelessWidget {
  const _PassFailAnalytics({required this.data});

  final ResultsAnalyticsLoaded data;

  @override
  Widget build(BuildContext context) {
    final rows = ResultsAnalyticsCalculator.subjectRows(data.data, data.filter);
    final summary = ResultsAnalyticsCalculator.subjectSummary(rows);
    final risks = ResultsAnalyticsCalculator.studentRiskSummaries(
      data.data,
      data.filter,
    );
    final absent = rows
        .where((row) => row.subject.isAbsent)
        .toList(growable: false);
    final oneFailure = risks
        .where((item) => item.failedSubjects == 1)
        .toList(growable: false);
    final multipleFailures = risks
        .where((item) => item.failedSubjects > 1)
        .toList(growable: false);
    final borderline = ResultsAnalyticsCalculator.borderlineRows(
      data.data,
      data.filter,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResultsAnalyticsFilterCard(
          data: data,
          showSubject: true,
          showSearch: true,
          showRiskThresholds: true,
        ),
        const SizedBox(height: 18),
        _MetricWrap(
          metrics: [
            _Metric(
              'Total Students',
              '${summary.totalStudents}',
              Icons.groups_outlined,
            ),
            _Metric(
              'Passed',
              '${summary.passedStudents}',
              Icons.check_circle_outline,
            ),
            _Metric(
              'Failed',
              '${summary.failedStudents}',
              Icons.cancel_outlined,
            ),
            _Metric(
              'Absent',
              '${summary.absentStudents}',
              Icons.person_off_outlined,
            ),
            _Metric(
              'Pass Percentage',
              _percent(summary.passPercentage),
              Icons.percent_outlined,
            ),
            _Metric(
              'Fail Percentage',
              _percent(summary.failPercentage),
              Icons.percent_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ChartGrid(
          children: [
            ResultsPieChart(
              title: 'Pass vs Fail',
              points: [
                ResultChartPoint(
                  label: 'Pass',
                  value: summary.passedStudents.toDouble(),
                ),
                ResultChartPoint(
                  label: 'Fail',
                  value: summary.failedStudents.toDouble(),
                ),
              ],
            ),
            ResultsBarChart(
              title: 'Failure Intervention Groups',
              points: [
                ResultChartPoint(
                  label: 'One subject',
                  value: oneFailure.length.toDouble(),
                ),
                ResultChartPoint(
                  label: 'Multiple',
                  value: multipleFailures.length.toDouble(),
                ),
                ResultChartPoint(
                  label: 'Absent',
                  value: absent.length.toDouble(),
                ),
                ResultChartPoint(
                  label: 'Borderline',
                  value: borderline.length.toDouble(),
                ),
              ],
              maxY: 1,
              valueSuffix: '',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _RiskLists(
          oneFailure: oneFailure,
          multipleFailures: multipleFailures,
          absent: absent,
          borderline: borderline,
        ),
      ],
    );
  }
}

class _TopWeakAnalytics extends StatelessWidget {
  const _TopWeakAnalytics({required this.data});

  final ResultsAnalyticsLoaded data;

  @override
  Widget build(BuildContext context) {
    final topThree = ResultsAnalyticsCalculator.topResults(
      data.data,
      data.filter,
      limit: 3,
    );
    final topTen = ResultsAnalyticsCalculator.topResults(
      data.data,
      data.filter,
      limit: 10,
    );
    final weakest = ResultsAnalyticsCalculator.topResults(
      data.data,
      data.filter,
      limit: 10,
      weakest: true,
    );
    final belowThreshold = data.results
        .where(
          (result) => result.percentage < data.filter.lowPerformanceThreshold,
        )
        .toList(growable: false);
    final multipleFailures = ResultsAnalyticsCalculator.studentRiskSummaries(
      data.data,
      data.filter,
    ).where((item) => item.failedSubjects > 1).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResultsAnalyticsFilterCard(data: data, showRiskThresholds: true),
        const SizedBox(height: 18),
        _MetricWrap(
          metrics: [
            _Metric(
              'Top 3',
              '${topThree.length}',
              Icons.workspace_premium_outlined,
            ),
            _Metric('Top 10', '${topTen.length}', Icons.emoji_events_outlined),
            _Metric(
              'Below ${_number(data.filter.lowPerformanceThreshold)}%',
              '${belowThreshold.length}',
              Icons.warning_amber_outlined,
            ),
            _Metric(
              'Multiple Subject Failures',
              '${multipleFailures.length}',
              Icons.flag_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _TopWeakTable(title: 'Top 3 Students', results: topThree),
        const SizedBox(height: 16),
        _TopWeakTable(title: 'Top 10 Students', results: topTen),
        const SizedBox(height: 16),
        _TopWeakTable(title: 'Lowest Performing Students', results: weakest),
        const SizedBox(height: 16),
        _TopWeakTable(
          title:
              'Students Below ${_number(data.filter.lowPerformanceThreshold)}%',
          results: belowThreshold,
        ),
        const SizedBox(height: 16),
        _RiskResultTable(
          title: 'Students Failing Multiple Subjects',
          items: multipleFailures,
        ),
      ],
    );
  }
}

class _MetricWrap extends StatelessWidget {
  const _MetricWrap({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1300
            ? 5
            : constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map(
                (metric) => SizedBox(width: width, height: 92, child: metric),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: colors.onPrimaryContainer, size: 21),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartGrid extends StatelessWidget {
  const _ChartGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850 ? 2 : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 16)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children
              .map((child) => SizedBox(width: width, height: 300, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

class _SubjectRowsTable extends StatelessWidget {
  const _SubjectRowsTable({required this.rows});

  final List<SubjectStudentAnalysisRow> rows;

  @override
  Widget build(BuildContext context) {
    return _TableCard(
      title: 'Student-level Subject Results',
      child: rows.isEmpty
          ? const _EmptyTable()
          : DataTable(
              columns: const [
                DataColumn(label: Text('Roll No')),
                DataColumn(label: Text('Admission No')),
                DataColumn(label: Text('Student Name')),
                DataColumn(label: Text('Obtained Marks'), numeric: true),
                DataColumn(label: Text('Percentage'), numeric: true),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Absent')),
              ],
              rows: rows
                  .map(
                    (row) => DataRow(
                      cells: [
                        DataCell(Text(_display(row.result.rollNumber))),
                        DataCell(Text(_display(row.result.admissionNo))),
                        DataCell(Text(row.result.studentName)),
                        DataCell(Text(_number(row.subject.obtainedMarks))),
                        DataCell(Text(_percent(row.percentage))),
                        DataCell(_PassFailChip(isPassed: row.subject.isPassed)),
                        DataCell(
                          Icon(
                            row.subject.isAbsent
                                ? Icons.check_circle_outline
                                : Icons.remove,
                            color: row.subject.isAbsent
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _StudentPerformanceTable extends StatelessWidget {
  const _StudentPerformanceTable({required this.summary});

  final StudentPerformanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return _TableCard(
      title: '${summary.studentName} - Exam Performance',
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Exam')),
          DataColumn(label: Text('Percentage'), numeric: true),
          DataColumn(label: Text('Grade')),
          DataColumn(label: Text('Position'), numeric: true),
          DataColumn(label: Text('Status')),
        ],
        rows: summary.examPerformances
            .map(
              (item) => DataRow(
                cells: [
                  DataCell(Text(item.examName)),
                  DataCell(Text(_percent(item.percentage))),
                  DataCell(Text(item.grade)),
                  DataCell(Text(item.position == 0 ? '-' : '${item.position}')),
                  DataCell(_PassFailChip(isPassed: item.isPassed)),
                ],
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ClassComparisonList extends StatelessWidget {
  const _ClassComparisonList({required this.items});

  final List<PerformanceGroupSummary> items;

  @override
  Widget build(BuildContext context) {
    return _TableCard(
      title: 'Class Performance Overview',
      child: items.isEmpty
          ? const _EmptyTable()
          : DataTable(
              columns: const [
                DataColumn(label: Text('Class')),
                DataColumn(label: Text('Students'), numeric: true),
                DataColumn(label: Text('Pass %'), numeric: true),
                DataColumn(label: Text('Average %'), numeric: true),
                DataColumn(label: Text('Top Performer')),
              ],
              rows: items
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(Text(item.name)),
                        DataCell(Text('${item.totalStudents}')),
                        DataCell(Text(_percent(item.passPercentage))),
                        DataCell(Text(_percent(item.averagePercentage))),
                        DataCell(Text(item.topPerformer?.studentName ?? '-')),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _ClassRankingTable extends StatelessWidget {
  const _ClassRankingTable({required this.results});

  final List<ExamResultEntity> results;

  @override
  Widget build(BuildContext context) {
    return _TableCard(
      title: 'Student Ranking',
      child: results.isEmpty
          ? const _EmptyTable()
          : DataTable(
              columns: const [
                DataColumn(label: Text('Position'), numeric: true),
                DataColumn(label: Text('Roll No')),
                DataColumn(label: Text('Admission No')),
                DataColumn(label: Text('Student Name')),
                DataColumn(label: Text('Total'), numeric: true),
                DataColumn(label: Text('Obtained'), numeric: true),
                DataColumn(label: Text('Percentage'), numeric: true),
                DataColumn(label: Text('Grade')),
                DataColumn(label: Text('Status')),
              ],
              rows: results
                  .map(
                    (result) => DataRow(
                      cells: [
                        DataCell(Text('${result.classPosition}')),
                        DataCell(Text(_display(result.rollNumber))),
                        DataCell(Text(_display(result.admissionNo))),
                        DataCell(Text(result.studentName)),
                        DataCell(Text(_number(result.grandTotalMarks))),
                        DataCell(Text(_number(result.grandObtainedMarks))),
                        DataCell(Text(_percent(result.percentage))),
                        DataCell(Text(result.grade)),
                        DataCell(_PassFailChip(isPassed: result.isPassed)),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _SectionComparisonTable extends StatelessWidget {
  const _SectionComparisonTable({required this.items});

  final List<PerformanceGroupSummary> items;

  @override
  Widget build(BuildContext context) {
    return _TableCard(
      title: 'Section Comparison',
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Section')),
          DataColumn(label: Text('Students'), numeric: true),
          DataColumn(label: Text('Passed'), numeric: true),
          DataColumn(label: Text('Failed'), numeric: true),
          DataColumn(label: Text('Pass %'), numeric: true),
          DataColumn(label: Text('Average %'), numeric: true),
          DataColumn(label: Text('Highest %'), numeric: true),
          DataColumn(label: Text('Lowest %'), numeric: true),
          DataColumn(label: Text('Top Performer')),
        ],
        rows: items
            .map(
              (item) => DataRow(
                cells: [
                  DataCell(Text(item.name)),
                  DataCell(Text('${item.totalStudents}')),
                  DataCell(Text('${item.passedStudents}')),
                  DataCell(Text('${item.failedStudents}')),
                  DataCell(Text(_percent(item.passPercentage))),
                  DataCell(Text(_percent(item.averagePercentage))),
                  DataCell(Text(_percent(item.highestPercentage))),
                  DataCell(Text(_percent(item.lowestPercentage))),
                  DataCell(Text(item.topPerformer?.studentName ?? '-')),
                ],
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _RiskLists extends StatelessWidget {
  const _RiskLists({
    required this.oneFailure,
    required this.multipleFailures,
    required this.absent,
    required this.borderline,
  });

  final List<StudentRiskSummary> oneFailure;
  final List<StudentRiskSummary> multipleFailures;
  final List<SubjectStudentAnalysisRow> absent;
  final List<SubjectStudentAnalysisRow> borderline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RiskResultTable(
          title: 'Students Failing One Subject',
          items: oneFailure,
        ),
        const SizedBox(height: 16),
        _RiskResultTable(
          title: 'Students Failing Multiple Subjects',
          items: multipleFailures,
        ),
        const SizedBox(height: 16),
        _SubjectRiskTable(title: 'Absent Students', rows: absent),
        const SizedBox(height: 16),
        _SubjectRiskTable(title: 'Borderline Students', rows: borderline),
      ],
    );
  }
}

class _RiskResultTable extends StatelessWidget {
  const _RiskResultTable({required this.title, required this.items});

  final String title;
  final List<StudentRiskSummary> items;

  @override
  Widget build(BuildContext context) {
    return _TableCard(
      title: title,
      child: items.isEmpty
          ? const _EmptyTable()
          : DataTable(
              columns: const [
                DataColumn(label: Text('Student')),
                DataColumn(label: Text('Roll No')),
                DataColumn(label: Text('Class / Section')),
                DataColumn(label: Text('Failed Subjects'), numeric: true),
                DataColumn(label: Text('Absent Subjects'), numeric: true),
                DataColumn(label: Text('Percentage'), numeric: true),
              ],
              rows: items
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(Text(item.result.studentName)),
                        DataCell(Text(_display(item.result.rollNumber))),
                        DataCell(
                          Text(
                            '${item.result.className}-${item.result.sectionName}',
                          ),
                        ),
                        DataCell(Text('${item.failedSubjects}')),
                        DataCell(Text('${item.absentSubjects}')),
                        DataCell(Text(_percent(item.result.percentage))),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _SubjectRiskTable extends StatelessWidget {
  const _SubjectRiskTable({required this.title, required this.rows});

  final String title;
  final List<SubjectStudentAnalysisRow> rows;

  @override
  Widget build(BuildContext context) {
    return _TableCard(
      title: title,
      child: rows.isEmpty
          ? const _EmptyTable()
          : DataTable(
              columns: const [
                DataColumn(label: Text('Student')),
                DataColumn(label: Text('Roll No')),
                DataColumn(label: Text('Subject')),
                DataColumn(label: Text('Marks'), numeric: true),
                DataColumn(label: Text('Passing'), numeric: true),
                DataColumn(label: Text('Class / Section')),
              ],
              rows: rows
                  .map(
                    (row) => DataRow(
                      cells: [
                        DataCell(Text(row.result.studentName)),
                        DataCell(Text(_display(row.result.rollNumber))),
                        DataCell(Text(row.subject.subjectName)),
                        DataCell(Text(_number(row.subject.obtainedMarks))),
                        DataCell(
                          Text(
                            row.passingMarks == null
                                ? '-'
                                : _number(row.passingMarks!),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${row.result.className}-${row.result.sectionName}',
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _TopWeakTable extends StatelessWidget {
  const _TopWeakTable({required this.title, required this.results});

  final String title;
  final List<ExamResultEntity> results;

  @override
  Widget build(BuildContext context) {
    return _TableCard(
      title: title,
      child: results.isEmpty
          ? const _EmptyTable()
          : DataTable(
              columns: const [
                DataColumn(label: Text('Position'), numeric: true),
                DataColumn(label: Text('Student')),
                DataColumn(label: Text('Class / Section')),
                DataColumn(label: Text('Percentage'), numeric: true),
                DataColumn(label: Text('Grade')),
                DataColumn(label: Text('Status')),
              ],
              rows: results
                  .map(
                    (result) => DataRow(
                      cells: [
                        DataCell(Text('${result.overallRank}')),
                        DataCell(Text(result.studentName)),
                        DataCell(
                          Text('${result.className}-${result.sectionName}'),
                        ),
                        DataCell(Text(_percent(result.percentage))),
                        DataCell(Text(result.grade)),
                        DataCell(_PassFailChip(isPassed: result.isPassed)),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _PassFailChip extends StatelessWidget {
  const _PassFailChip({required this.isPassed});

  final bool isPassed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(isPassed ? 'Pass' : 'Fail'),
      backgroundColor: isPassed
          ? Colors.green.withValues(alpha: 0.16)
          : colors.errorContainer,
      labelStyle: TextStyle(
        color: isPassed ? Colors.green.shade800 : colors.onErrorContainer,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EmptyTable extends StatelessWidget {
  const _EmptyTable();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Text('No published result data is available for this selection.'),
  );
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 72),
    child: Center(child: Text(message, textAlign: TextAlign.center)),
  );
}

class _AnalyticsFailure extends StatelessWidget {
  const _AnalyticsFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 46),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<ResultsAnalyticsBloc>().add(
              const LoadResultsAnalytics(),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    ),
  );
}

String _title(ResultsAnalyticsView view) {
  switch (view) {
    case ResultsAnalyticsView.overview:
      return 'Overall Result Statistics';
    case ResultsAnalyticsView.subject:
      return 'Subject Analysis';
    case ResultsAnalyticsView.student:
      return 'Student Performance';
    case ResultsAnalyticsView.classPerformance:
      return 'Class Performance';
    case ResultsAnalyticsView.sectionComparison:
      return 'Section Comparison';
    case ResultsAnalyticsView.passFail:
      return 'Pass / Fail Analysis';
    case ResultsAnalyticsView.topAndWeak:
      return 'Top & Weak Student Analysis';
  }
}

String _percent(double value) => '${value.toStringAsFixed(1)}%';

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

String _display(String value) => value.trim().isEmpty ? '-' : value;
