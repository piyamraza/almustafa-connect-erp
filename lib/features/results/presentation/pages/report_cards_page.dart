import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
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
import 'individual_report_card_page.dart';

class ReportCardsPage extends StatelessWidget {
  const ReportCardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResultsBloc>()..add(const LoadPublishedResults()),
      child: const _ReportCardsView(),
    );
  }
}

class _ReportCardsView extends StatelessWidget {
  const _ReportCardsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Cards'),
        actions: [
          const DashboardNavigationButton(),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context.read<ResultsBloc>().add(
              const RefreshPublishedResults(),
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<ResultsBloc, ResultsState>(
        builder: (context, state) => switch (state) {
          ResultsInitial() ||
          ResultsLoading() => const Center(child: CircularProgressIndicator()),
          ResultsFailure(:final message) => _ErrorState(message: message),
          PublishedResultsLoaded() => _ReportCardsContent(data: state),
        },
      ),
    );
  }
}

class _ReportCardsContent extends StatelessWidget {
  const _ReportCardsContent({required this.data});

  final PublishedResultsLoaded data;

  @override
  Widget build(BuildContext context) {
    final results = data.filteredResults;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (data.isLoading) const LinearProgressIndicator(),
            if (data.isLoading) const SizedBox(height: 12),
            PublishedResultsFilterCard(data: data, includeStudent: true),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${results.length} published report card${results.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                ResultsExportActions(
                  request: ResultExportRequestFactory.fromPublishedResults(
                    type: ResultExportType.bulkReportCards,
                    title: 'Bulk Report Cards',
                    results: results,
                    data: data,
                    metrics: ResultExportRequestFactory.summaryMetrics(results),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: results.isEmpty
                  ? const _EmptyState(
                      message:
                          'No published report cards match the selected filters.',
                    )
                  : _ReportCardList(results: results),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCardList extends StatelessWidget {
  const _ReportCardList({required this.results});

  final List<ExamResultEntity> results;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showDesktopColumns = constraints.maxWidth >= 760;
        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (showDesktopColumns) const _ReportCardListHeader(),
              Expanded(
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _ReportCardRow(
                    result: results[index],
                    showDesktopColumns: showDesktopColumns,
                    onTap: () => _open(context, results[index]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _open(BuildContext context, ExamResultEntity result) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IndividualReportCardPage(result: result),
      ),
    );
  }
}

class _ReportCardListHeader extends StatelessWidget {
  const _ReportCardListHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
    return Container(
      height: 38,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 36),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: Text('Student', style: style)),
          Expanded(flex: 2, child: Text('Class / Roll No.', style: style)),
          Expanded(flex: 3, child: Text('Exam / Session', style: style)),
          Expanded(flex: 2, child: Text('Result', style: style)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ReportCardRow extends StatelessWidget {
  const _ReportCardRow({
    required this.result,
    required this.showDesktopColumns,
    required this.onTap,
  });

  final ExamResultEntity result;
  final bool showDesktopColumns;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = result.studentName.trim().isEmpty
        ? '?'
        : result.studentName.trim()[0].toUpperCase();
    final resultText =
        '${result.percentage.toStringAsFixed(1)}% • ${result.grade}';

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: showDesktopColumns ? 56 : 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: showDesktopColumns
              ? Row(
                  children: [
                    CircleAvatar(radius: 18, child: Text(initial)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Text(
                        result.studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${result.className}-${result.sectionName}  •  ${result.rollNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${result.examName} • ${result.academicSession}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        resultText,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Open report card',
                      visualDensity: VisualDensity.compact,
                      onPressed: onTap,
                      icon: const Icon(Icons.description_outlined, size: 20),
                    ),
                  ],
                )
              : Row(
                  children: [
                    CircleAvatar(radius: 17, child: Text(initial)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${result.className}-${result.sectionName} • Roll ${result.rollNumber} • ${result.examName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      resultText,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

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
