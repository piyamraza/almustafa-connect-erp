import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/exam_result_entity.dart';
import '../bloc/exam_results_bloc.dart';
import '../bloc/exam_results_event.dart';
import '../bloc/exam_results_state.dart';
import '../widgets/result_statistic_card.dart';
import '../widgets/result_status_chip.dart';

class ResultSummaryPage extends StatelessWidget {
  const ResultSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExamResultsBloc>()..add(const LoadResultSummary()),
      child: const _ResultSummaryView(),
    );
  }
}

class _ResultSummaryView extends StatelessWidget {
  const _ResultSummaryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result Review'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<ExamResultsBloc>()
                .add(const RefreshResultSummary()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<ExamResultsBloc, ExamResultsState>(
        listenWhen: (previous, current) => current is ExamResultsLoaded &&
            (current.successMessage != null || current.errorMessage != null),
        listener: (context, state) {
          if (state is! ExamResultsLoaded) return;
          final message = state.errorMessage ?? state.successMessage;
          if (message == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: state.errorMessage == null
                    ? null
                    : Theme.of(context).colorScheme.error,
              ),
            );
        },
        builder: (context, state) {
          return switch (state) {
            ExamResultsInitial() || ExamResultsLoading() =>
              const Center(child: CircularProgressIndicator()),
            ExamResultsFailure(:final message) => _FailureView(
                message: message,
                onRetry: () => context
                    .read<ExamResultsBloc>()
                    .add(const LoadResultSummary()),
              ),
            ExamResultsLoaded() => _LoadedResultSummary(data: state),
          };
        },
      ),
    );
  }
}

class _LoadedResultSummary extends StatelessWidget {
  const _LoadedResultSummary({required this.data});

  final ExamResultsLoaded data;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ExamResultsBloc>();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (data.isLoading || data.isProcessing)
              const LinearProgressIndicator(),
            if (data.isLoading || data.isProcessing) const SizedBox(height: 12),
            _ResultFilters(
              data: data,
              onExamChanged: (value) {
                if (value != null) bloc.add(SelectResultExam(value));
              },
              onClassChanged: (value) => bloc.add(SelectResultClass(value)),
              onSectionChanged: (value) => bloc.add(SelectResultSection(value)),
            ),
            const SizedBox(height: 14),
            _ResultActions(
              data: data,
              onGenerate: () => _confirmAndDispatch(
                context,
                title: 'Generate results?',
                message:
                    'This recalculates all unlocked results for the selected exam from saved marks.',
                event: const GenerateSelectedExamResults(),
              ),
              onPublish: () => _confirmAndDispatch(
                context,
                title: 'Publish results?',
                message:
                    'The results matching the active filters will be published.',
                event: const ChangeFilteredResultsStatus(ResultStatus.published),
              ),
              onUnpublish: () => _confirmAndDispatch(
                context,
                title: 'Unpublish results?',
                message:
                    'The results matching the active filters will no longer be published.',
                event: const ChangeFilteredResultsStatus(ResultStatus.unpublished),
              ),
              onLock: () => _confirmAndDispatch(
                context,
                title: 'Lock published results?',
                message:
                    'Locked results become read-only and cannot be regenerated in this module.',
                event: const ChangeFilteredResultsStatus(ResultStatus.locked),
              ),
              onUnlock: () => _confirmAndDispatch(
                context,
                title: 'Unlock results?',
                message:
                    'The matching locked results will become published and editable again.',
                event: const UnlockFilteredResults(),
              ),
            ),
            const SizedBox(height: 14),
            _ResultStatistics(data: data),
            const SizedBox(height: 14),
            Expanded(
              child: _ResultsTable(
                results: data.filteredResults,
                hasSelectedExam: data.selectedExamId != null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDispatch(
    BuildContext context, {
    required String title,
    required String message,
    required ExamResultsEvent event,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ExamResultsBloc>().add(event);
    }
  }
}

class _ResultFilters extends StatelessWidget {
  const _ResultFilters({
    required this.data,
    required this.onExamChanged,
    required this.onClassChanged,
    required this.onSectionChanged,
  });

  final ExamResultsLoaded data;
  final ValueChanged<String?> onExamChanged;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onSectionChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = !data.isLoading && !data.isProcessing;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _ResultSelect(
              label: 'Exam',
              value: data.selectedExamId,
              enabled: enabled,
              items: data.availableExams
                  .map((exam) => _SelectItem(exam.id, exam.name))
                  .toList(growable: false),
              onChanged: onExamChanged,
            ),
            _ResultSelect(
              label: 'Class',
              value: data.selectedClassId,
              enabled: enabled && data.selectedExamId != null,
              allowAll: true,
              items: data.availableClasses
                  .map((setup) => _SelectItem(setup.classId, setup.className))
                  .toList(growable: false),
              onChanged: onClassChanged,
            ),
            _ResultSelect(
              label: 'Section',
              value: data.selectedSectionId,
              enabled: enabled && data.selectedClassId != null,
              allowAll: true,
              items: data.availableSections
                  .map((setup) => _SelectItem(setup.sectionId, setup.sectionName))
                  .toList(growable: false),
              onChanged: onSectionChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({
    required this.data,
    required this.onGenerate,
    required this.onPublish,
    required this.onUnpublish,
    required this.onLock,
    required this.onUnlock,
  });

  final ExamResultsLoaded data;
  final VoidCallback onGenerate;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final VoidCallback onLock;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final isBusy = data.isLoading || data.isProcessing;
    final results = data.filteredResults;
    final statuses = results.map((result) => result.status).toSet();
    final canGenerate = data.selectedExamId != null && !isBusy;
    final canPublish = !isBusy &&
        results.isNotEmpty &&
        statuses.every(
          (status) =>
              status == ResultStatus.draft || status == ResultStatus.unpublished,
        );
    final canUnpublish = !isBusy &&
        results.isNotEmpty &&
        statuses.every((status) => status == ResultStatus.published);
    final canLock = canUnpublish;
    final canUnlock = !isBusy &&
        results.isNotEmpty &&
        statuses.every((status) => status == ResultStatus.locked);
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton.icon(
            onPressed: canGenerate ? onGenerate : null,
            icon: const Icon(Icons.calculate_outlined),
            label: Text(data.isProcessing ? 'Processing...' : 'Generate Results'),
          ),
          OutlinedButton.icon(
            onPressed: canPublish ? onPublish : null,
            icon: const Icon(Icons.publish_outlined),
            label: const Text('Publish'),
          ),
          OutlinedButton.icon(
            onPressed: canUnpublish ? onUnpublish : null,
            icon: const Icon(Icons.unpublished_outlined),
            label: const Text('Unpublish'),
          ),
          OutlinedButton.icon(
            onPressed: canLock ? onLock : null,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Lock'),
          ),
          OutlinedButton.icon(
            onPressed: canUnlock ? onUnlock : null,
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}

class _ResultStatistics extends StatelessWidget {
  const _ResultStatistics({required this.data});

  final ExamResultsLoaded data;

  @override
  Widget build(BuildContext context) {
    final statistics = data.statistics;
    final colors = Theme.of(context).colorScheme;
    final cards = [
      ResultStatisticCard(label: 'Total Students', value: '${statistics.totalStudents}', icon: Icons.groups_outlined, color: colors.primary),
      ResultStatisticCard(label: 'Passed', value: '${statistics.passedStudents}', icon: Icons.check_circle_outline, color: Colors.green),
      ResultStatisticCard(label: 'Failed', value: '${statistics.failedStudents}', icon: Icons.cancel_outlined, color: colors.error),
      ResultStatisticCard(label: 'Pass Percentage', value: _percentage(statistics.passPercentage), icon: Icons.percent_outlined, color: colors.tertiary),
      ResultStatisticCard(label: 'Highest Percentage', value: _percentage(statistics.highestPercentage), icon: Icons.north_outlined, color: Colors.teal),
      ResultStatisticCard(label: 'Lowest Percentage', value: _percentage(statistics.lowestPercentage), icon: Icons.south_outlined, color: Colors.deepOrange),
      ResultStatisticCard(label: 'Average Percentage', value: _percentage(statistics.averagePercentage), icon: Icons.analytics_outlined, color: Colors.indigo),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1350 ? 4 : width >= 940 ? 3 : width >= 620 ? 2 : 1;
        final cardWidth = (width - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (card) => SizedBox(width: cardWidth, height: 94, child: card),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _ResultsTable extends StatelessWidget {
  const _ResultsTable({required this.results, required this.hasSelectedExam});

  final List<ExamResultEntity> results;
  final bool hasSelectedExam;

  @override
  Widget build(BuildContext context) {
    if (!hasSelectedExam) {
      return const _EmptyView(
        icon: Icons.school_outlined,
        message: 'Select an exam to view and generate results.',
      );
    }
    if (results.isEmpty) {
      return const _EmptyView(
        icon: Icons.calculate_outlined,
        message: 'No calculated results match the current filters.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return ListView.separated(
            itemCount: results.length,
            padding: const EdgeInsets.only(bottom: 4),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _MobileResultCard(result: results[index]),
          );
        }
        return _DesktopResultsTable(results: results);
      },
    );
  }
}

class _DesktopResultsTable extends StatelessWidget {
  const _DesktopResultsTable({required this.results});

  final List<ExamResultEntity> results;

  @override
  Widget build(BuildContext context) {
    const rollWidth = 75.0;
    const totalWidth = 95.0;
    const obtainedWidth = 105.0;
    const percentageWidth = 95.0;
    const gradeWidth = 70.0;
    const resultWidth = 80.0;
    const rankWidth = 70.0;
    const statusWidth = 118.0;
    const fixedWidth = rollWidth + totalWidth + obtainedWidth + percentageWidth + gradeWidth + resultWidth + rankWidth * 3 + statusWidth;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final studentWidth = (constraints.maxWidth - fixedWidth)
              .clamp(210.0, double.infinity)
              .toDouble();
          return Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(
                  children: [
                    const SizedBox(width: rollWidth, child: _HeaderText('Roll')),
                    SizedBox(width: studentWidth, child: const _HeaderText('Student')),
                    const SizedBox(width: totalWidth, child: _HeaderText('Total')),
                    const SizedBox(width: obtainedWidth, child: _HeaderText('Obtained')),
                    const SizedBox(width: percentageWidth, child: _HeaderText('%')),
                    const SizedBox(width: gradeWidth, child: _HeaderText('Grade')),
                    const SizedBox(width: resultWidth, child: _HeaderText('Result')),
                    const SizedBox(width: rankWidth, child: _HeaderText('Section')),
                    const SizedBox(width: rankWidth, child: _HeaderText('Class')),
                    const SizedBox(width: rankWidth, child: _HeaderText('Overall')),
                    const SizedBox(width: statusWidth, child: _HeaderText('Status')),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(width: rollWidth, child: Text(_value(result.rollNumber))),
                          SizedBox(width: studentWidth, child: _StudentCell(result: result)),
                          SizedBox(width: totalWidth, child: Text(_number(result.grandTotalMarks))),
                          SizedBox(width: obtainedWidth, child: Text(_number(result.grandObtainedMarks))),
                          SizedBox(width: percentageWidth, child: Text(_percentage(result.percentage))),
                          SizedBox(width: gradeWidth, child: Text(result.grade)),
                          SizedBox(width: resultWidth, child: _PassFailLabel(isPassed: result.isPassed)),
                          SizedBox(width: rankWidth, child: Text('${result.sectionPosition}')),
                          SizedBox(width: rankWidth, child: Text('${result.classPosition}')),
                          SizedBox(width: rankWidth, child: Text('${result.overallRank}')),
                          SizedBox(width: statusWidth, child: ResultStatusChip(status: result.status)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MobileResultCard extends StatelessWidget {
  const _MobileResultCard({required this.result});

  final ExamResultEntity result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _StudentCell(result: result)),
                ResultStatusChip(status: result.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _ResultDetail(label: 'Total', value: _number(result.grandTotalMarks)),
                _ResultDetail(label: 'Obtained', value: _number(result.grandObtainedMarks)),
                _ResultDetail(label: 'Percentage', value: _percentage(result.percentage)),
                _ResultDetail(label: 'Grade', value: result.grade),
                _ResultDetail(label: 'Result', value: result.isPassed ? 'Pass' : 'Fail'),
                _ResultDetail(label: 'Section Rank', value: '${result.sectionPosition}'),
                _ResultDetail(label: 'Class Rank', value: '${result.classPosition}'),
                _ResultDetail(label: 'Overall Rank', value: '${result.overallRank}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCell extends StatelessWidget {
  const _StudentCell({required this.result});

  final ExamResultEntity result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(result.studentName, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(
          '${result.className}-${result.sectionName} • ${result.admissionNo}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PassFailLabel extends StatelessWidget {
  const _PassFailLabel({required this.isPassed});

  final bool isPassed;

  @override
  Widget build(BuildContext context) {
    return Text(
      isPassed ? 'Pass' : 'Fail',
      style: TextStyle(
        color: isPassed ? Colors.green.shade700 : Theme.of(context).colorScheme.error,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ResultDetail extends StatelessWidget {
  const _ResultDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ResultSelect extends StatelessWidget {
  const _ResultSelect({
    required this.label,
    required this.value,
    required this.enabled,
    required this.items,
    required this.onChanged,
    this.allowAll = false,
  });

  final String label;
  final String? value;
  final bool enabled;
  final List<_SelectItem> items;
  final ValueChanged<String?> onChanged;
  final bool allowAll;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: DropdownButtonFormField<String>(
        value: items.any((item) => item.id == value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: [
          if (allowAll)
            const DropdownMenuItem<String>(value: null, child: Text('All')),
          ...items.map(
            (item) => DropdownMenuItem<String>(
              value: item.id,
              child: Text(item.label, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(value, style: const TextStyle(fontWeight: FontWeight.w700));
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

class _SelectItem {
  const _SelectItem(this.id, this.label);

  final String id;
  final String label;
}

String _percentage(double value) => '${value.toStringAsFixed(1)}%';

String _number(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);

String _value(String value) => value.trim().isEmpty ? '-' : value;
