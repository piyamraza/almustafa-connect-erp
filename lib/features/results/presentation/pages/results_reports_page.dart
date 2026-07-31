import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../domain/entities/result_export_request.dart';
import '../bloc/results_bloc.dart';
import '../bloc/results_event.dart';
import '../bloc/results_state.dart';
import '../widgets/published_results_filter_card.dart';
import '../widgets/result_export_request_factory.dart';
import '../widgets/results_export_actions.dart';

class ResultsReportsPage extends StatelessWidget {
  const ResultsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResultsBloc>()..add(const LoadPublishedResults()),
      child: const _ResultsReportsView(),
    );
  }
}

class _ResultsReportsView extends StatelessWidget {
  const _ResultsReportsView();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Results Reports'),
      actions: [
        IconButton(
          tooltip: 'Refresh published results',
          onPressed: () =>
              context.read<ResultsBloc>().add(const RefreshPublishedResults()),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: BlocBuilder<ResultsBloc, ResultsState>(
      builder: (context, state) => switch (state) {
        ResultsInitial() ||
        ResultsLoading() => const Center(child: CircularProgressIndicator()),
        ResultsFailure(:final message) => _ReportsError(message: message),
        PublishedResultsLoaded() => _ResultsReportsContent(data: state),
      },
    ),
  );
}

class _ResultsReportsContent extends StatelessWidget {
  const _ResultsReportsContent({required this.data});

  final PublishedResultsLoaded data;

  @override
  Widget build(BuildContext context) {
    final results = data.filteredResults;
    final topStudents = [...results]
      ..sort((first, second) => second.percentage.compareTo(first.percentage));
    final reportItems = [
      _ReportItem(
        title: 'Class Performance',
        description: 'Published class, section, and student performance sheet.',
        icon: Icons.groups_outlined,
        type: ResultExportType.classPerformance,
        results: results,
      ),
      _ReportItem(
        title: 'Subject Analysis',
        description:
            'Subject-wise marks, pass/fail status, and absent details.',
        icon: Icons.menu_book_outlined,
        type: ResultExportType.subjectAnalysis,
        results: results,
      ),
      _ReportItem(
        title: 'Pass / Fail Report',
        description: 'Published pass/fail summary for the selected results.',
        icon: Icons.fact_check_outlined,
        type: ResultExportType.passFail,
        results: results,
      ),
      _ReportItem(
        title: 'Failed Students',
        description: 'Students with an overall published fail result.',
        icon: Icons.person_off_outlined,
        type: ResultExportType.failedStudents,
        results: results
            .where((result) => !result.isPassed)
            .toList(growable: false),
      ),
      _ReportItem(
        title: 'Top 10 Students',
        description:
            'Highest percentages from the selected published result set.',
        icon: Icons.emoji_events_outlined,
        type: ResultExportType.topStudents,
        results: topStudents.take(10).toList(growable: false),
      ),
      _ReportItem(
        title: 'Overall Statistics',
        description: 'Summary with pass percentage and grade distribution.',
        icon: Icons.assessment_outlined,
        type: ResultExportType.overallStatistics,
        results: results,
      ),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (data.isLoading) const LinearProgressIndicator(),
            if (data.isLoading) const SizedBox(height: 12),
            PublishedResultsFilterCard(data: data),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${results.length} published result${results.length == 1 ? '' : 's'} selected',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 10.0;
                  final fitsInOneRow = constraints.maxWidth >= 1100;
                  final cardWidth = fitsInOneRow
                      ? (constraints.maxWidth -
                              (spacing * (reportItems.length - 1))) /
                          reportItems.length
                      : 220.0;
                  return Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      height: 176,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var index = 0;
                                index < reportItems.length;
                                index++) ...[
                              if (index > 0) const SizedBox(width: spacing),
                              SizedBox(
                                width: cardWidth,
                                child: _ReportCard(
                                  item: reportItems[index],
                                  data: data,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportItem {
  const _ReportItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.results,
  });

  final String title;
  final String description;
  final IconData icon;
  final ResultExportType type;
  final List<ExamResultEntity> results;
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.item, required this.data});

  final _ReportItem item;
  final PublishedResultsLoaded data;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ResultsExportActions(
                compact: true,
                request: ResultExportRequestFactory.fromPublishedResults(
                  type: item.type,
                  title: item.title,
                  results: item.results,
                  data: data,
                  metrics: ResultExportRequestFactory.summaryMetrics(
                    item.results,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            '${item.results.length} published student${item.results.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    ),
  );
}

class _ReportsError extends StatelessWidget {
  const _ReportsError({required this.message});

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
            onPressed: () =>
                context.read<ResultsBloc>().add(const LoadPublishedResults()),
            child: const Text('Try Again'),
          ),
        ],
      ),
    ),
  );
}
