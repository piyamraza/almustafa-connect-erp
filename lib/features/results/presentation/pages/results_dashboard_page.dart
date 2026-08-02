import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/presentation/widgets/result_statistic_card.dart';
import '../../../exams/presentation/widgets/result_status_chip.dart';
import '../bloc/results_bloc.dart';
import '../bloc/results_event.dart';
import '../bloc/results_state.dart';
import 'published_results_page.dart';
import 'student_result_details_page.dart';

class ResultsDashboardPage extends StatelessWidget {
  const ResultsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResultsBloc>()..add(const LoadPublishedResults()),
      child: const _ResultsDashboardView(),
    );
  }
}

class _ResultsDashboardView extends StatelessWidget {
  const _ResultsDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results Dashboard'),
        actions: [const DashboardNavigationButton(),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<ResultsBloc>()
                .add(const RefreshPublishedResults()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<ResultsBloc, ResultsState>(
        builder: (context, state) {
          return switch (state) {
            ResultsInitial() || ResultsLoading() =>
              const Center(child: CircularProgressIndicator()),
            ResultsFailure(:final message) => _FailureView(message: message),
            PublishedResultsLoaded() => _DashboardContent(data: state),
          };
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});

  final PublishedResultsLoaded data;

  @override
  Widget build(BuildContext context) {
    final results = data.results;
    final colors = Theme.of(context).colorScheme;
    final uniqueStudentIds = results.map((result) => result.studentId).toSet();
    final failedStudents = results
        .where((result) => !result.isPassed)
        .map((result) => result.studentId)
        .toSet();
    final topPerformer = _topPerformer(results);
    final passPercentage = results.isEmpty
        ? 0.0
        : (results.where((result) => result.isPassed).length / results.length) *
            100;
    final cards = [
      ResultStatisticCard(
        label: 'Total Published Results',
        value: '${results.length}',
        icon: Icons.fact_check_outlined,
        color: colors.primary,
      ),
      ResultStatisticCard(
        label: 'Total Students',
        value: '${uniqueStudentIds.length}',
        icon: Icons.groups_outlined,
        color: Colors.indigo,
      ),
      ResultStatisticCard(
        label: 'Overall Pass Percentage',
        value: '${passPercentage.toStringAsFixed(1)}%',
        icon: Icons.percent_outlined,
        color: Colors.green,
      ),
      ResultStatisticCard(
        label: 'Top Performer',
        value: topPerformer == null ? '-' : topPerformer.studentName,
        icon: Icons.emoji_events_outlined,
        color: Colors.amber.shade800,
      ),
      ResultStatisticCard(
        label: 'Failed Students',
        value: '${failedStudents.length}',
        icon: Icons.warning_amber_outlined,
        color: colors.error,
      ),
    ];
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1450),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.isLoading) const LinearProgressIndicator(),
                Text(
                  'Published Results',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This module is read-only. Draft and unpublished examination results are not displayed.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                _DashboardCards(cards: cards),
                const SizedBox(height: 22),
                _QuickViews(topPerformer: topPerformer),
                const SizedBox(height: 22),
                _RecentlyPublishedResults(results: results),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCards extends StatelessWidget {
  const _DashboardCards({required this.cards});

  final List<ResultStatisticCard> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1240
            ? 5
            : constraints.maxWidth >= 850
                ? 3
                : constraints.maxWidth >= 560
                    ? 2
                    : 1;
        final width =
            (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: width, height: 98, child: card))
              .toList(growable: false),
        );
      },
    );
  }
}

class _QuickViews extends StatelessWidget {
  const _QuickViews({required this.topPerformer});

  final ExamResultEntity? topPerformer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'View Published Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _open(context, ResultsViewType.studentResults),
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('Student Results'),
            ),
            OutlinedButton.icon(
              onPressed: () => _open(context, ResultsViewType.classResults),
              icon: const Icon(Icons.groups_outlined),
              label: const Text('Class Results'),
            ),
            OutlinedButton.icon(
              onPressed: () => _open(context, ResultsViewType.sectionResults),
              icon: const Icon(Icons.group_work_outlined),
              label: const Text('Section Results'),
            ),
            if (topPerformer != null)
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StudentResultDetailsPage(result: topPerformer!),
                  ),
                ),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Open Top Performer'),
              ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, ResultsViewType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PublishedResultsPage(type: type)),
    );
  }
}

class _RecentlyPublishedResults extends StatelessWidget {
  const _RecentlyPublishedResults({required this.results});

  final List<ExamResultEntity> results;

  @override
  Widget build(BuildContext context) {
    final recent = [...results]
      ..sort(
        (first, second) => (second.publishedAt ?? second.updatedAt)
            .compareTo(first.publishedAt ?? first.updatedAt),
      );
    final visible = recent.take(8).toList(growable: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recently Published Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              const _EmptyRecentResults()
            else
              ...visible.map(
                (result) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${result.overallRank}')),
                  title: Text(result.studentName),
                  subtitle: Text('${result.examName} • ${result.className}-${result.sectionName} • ${_date(result.updatedAt)}'),
                  trailing: ResultStatusChip(status: result.status),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => StudentResultDetailsPage(result: result),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecentResults extends StatelessWidget {
  const _EmptyRecentResults();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text('No published results are available yet.')),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
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
              onPressed: () => context
                  .read<ResultsBloc>()
                  .add(const LoadPublishedResults()),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

ExamResultEntity? _topPerformer(List<ExamResultEntity> results) {
  if (results.isEmpty) return null;
  final ranked = [...results]
    ..sort((first, second) {
      final percentage = second.percentage.compareTo(first.percentage);
      if (percentage != 0) return percentage;
      return first.overallRank.compareTo(second.overallRank);
    });
  return ranked.first;
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
