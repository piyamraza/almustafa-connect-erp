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

enum MeritScope { overall, classMerit, section }

class MeritListPage extends StatelessWidget {
  const MeritListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResultsBloc>()..add(const LoadPublishedResults()),
      child: const _MeritListView(),
    );
  }
}

class _MeritListView extends StatefulWidget {
  const _MeritListView();

  @override
  State<_MeritListView> createState() => _MeritListViewState();
}

class _MeritListViewState extends State<_MeritListView> {
  MeritScope _scope = MeritScope.overall;
  int _topLimit = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merit List'),
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
          ResultsFailure(:final message) => _MeritError(message: message),
          PublishedResultsLoaded() => _MeritContent(
            data: state,
            scope: _scope,
            topLimit: _topLimit,
            onScopeChanged: (value) => setState(() => _scope = value),
            onLimitChanged: (value) => setState(() => _topLimit = value),
          ),
        },
      ),
    );
  }
}

class _MeritContent extends StatelessWidget {
  const _MeritContent({
    required this.data,
    required this.scope,
    required this.topLimit,
    required this.onScopeChanged,
    required this.onLimitChanged,
  });

  final PublishedResultsLoaded data;
  final MeritScope scope;
  final int topLimit;
  final ValueChanged<MeritScope> onScopeChanged;
  final ValueChanged<int> onLimitChanged;

  @override
  Widget build(BuildContext context) {
    final ready = _isReady(data, scope);
    final results = ready
        ? _meritResults(data.filteredResults, scope, topLimit)
        : const <ExamResultEntity>[];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (data.isLoading) const LinearProgressIndicator(),
            if (data.isLoading) const SizedBox(height: 12),
            PublishedResultsFilterCard(data: data),
            const SizedBox(height: 12),
            _MeritControls(
              scope: scope,
              topLimit: topLimit,
              onScopeChanged: onScopeChanged,
              onLimitChanged: onLimitChanged,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ResultsExportActions(
                request: ResultExportRequestFactory.fromPublishedResults(
                  type: ResultExportType.meritList,
                  title: '${_scopeLabel(scope)} Merit List - Top $topLimit',
                  results: results,
                  data: data,
                  metrics: ResultExportRequestFactory.summaryMetrics(results),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ready
                  ? _MeritTable(results: results, scope: scope)
                  : _MeritSelectionHint(scope: scope),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeritControls extends StatelessWidget {
  const _MeritControls({
    required this.scope,
    required this.topLimit,
    required this.onScopeChanged,
    required this.onLimitChanged,
  });

  final MeritScope scope;
  final int topLimit;
  final ValueChanged<MeritScope> onScopeChanged;
  final ValueChanged<int> onLimitChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Merit scope',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            ChoiceChip(
              label: const Text('Overall Merit'),
              selected: scope == MeritScope.overall,
              onSelected: (_) => onScopeChanged(MeritScope.overall),
            ),
            ChoiceChip(
              label: const Text('Class Merit'),
              selected: scope == MeritScope.classMerit,
              onSelected: (_) => onScopeChanged(MeritScope.classMerit),
            ),
            ChoiceChip(
              label: const Text('Section Merit'),
              selected: scope == MeritScope.section,
              onSelected: (_) => onScopeChanged(MeritScope.section),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Top 3'),
              selected: topLimit == 3,
              onSelected: (_) => onLimitChanged(3),
            ),
            ChoiceChip(
              label: const Text('Top 10'),
              selected: topLimit == 10,
              onSelected: (_) => onLimitChanged(10),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeritTable extends StatelessWidget {
  const _MeritTable({required this.results, required this.scope});

  final List<ExamResultEntity> results;
  final MeritScope scope;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No published merit records are available for this selection.',
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final result = results[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${_rank(result, scope)}')),
                  title: Text(result.studentName),
                  subtitle: Text(
                    '${result.percentage.toStringAsFixed(1)}% • Grade ${result.grade}',
                  ),
                ),
              );
            },
          );
        }
        return Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              columns: const [
                DataColumn(label: Text('Position')),
                DataColumn(label: Text('Student')),
                DataColumn(label: Text('Percentage')),
                DataColumn(label: Text('Grade')),
              ],
              rows: results
                  .map(
                    (result) => DataRow(
                      cells: [
                        DataCell(Text('${_rank(result, scope)}')),
                        DataCell(Text(result.studentName)),
                        DataCell(
                          Text('${result.percentage.toStringAsFixed(1)}%'),
                        ),
                        DataCell(Text(result.grade)),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        );
      },
    );
  }
}

class _MeritSelectionHint extends StatelessWidget {
  const _MeritSelectionHint({required this.scope});

  final MeritScope scope;

  @override
  Widget build(BuildContext context) {
    final message = switch (scope) {
      MeritScope.overall =>
        'Select academic session and exam to view overall merit.',
      MeritScope.classMerit =>
        'Select academic session, exam, and class to view class merit.',
      MeritScope.section =>
        'Select academic session, exam, class, and section to view section merit.',
    };
    return Center(child: Text(message, textAlign: TextAlign.center));
  }
}

class _MeritError extends StatelessWidget {
  const _MeritError({required this.message});

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

bool _isReady(PublishedResultsLoaded data, MeritScope scope) {
  if (data.selectedAcademicSession == null || data.selectedExamId == null) {
    return false;
  }
  if (scope == MeritScope.overall) return true;
  if (data.selectedClassId == null) return false;
  return scope != MeritScope.section || data.selectedSectionId != null;
}

List<ExamResultEntity> _meritResults(
  List<ExamResultEntity> results,
  MeritScope scope,
  int topLimit,
) {
  final values = results.where((result) => _rank(result, scope) > 0).toList();
  values.sort((first, second) {
    final rank = _rank(first, scope).compareTo(_rank(second, scope));
    if (rank != 0) return rank;
    return second.percentage.compareTo(first.percentage);
  });
  return values
      .where((result) => _rank(result, scope) <= topLimit)
      .toList(growable: false);
}

int _rank(ExamResultEntity result, MeritScope scope) => switch (scope) {
  MeritScope.overall => result.overallRank,
  MeritScope.classMerit => result.classPosition,
  MeritScope.section => result.sectionPosition,
};

String _scopeLabel(MeritScope scope) => switch (scope) {
  MeritScope.overall => 'Overall',
  MeritScope.classMerit => 'Class',
  MeritScope.section => 'Section',
};
