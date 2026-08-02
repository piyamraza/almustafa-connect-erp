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

enum ResultSheetKind { classSheet, sectionSheet }

class ResultSheetPage extends StatelessWidget {
  const ResultSheetPage({required this.kind, super.key});

  final ResultSheetKind kind;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResultsBloc>()..add(const LoadPublishedResults()),
      child: _ResultSheetView(kind: kind),
    );
  }
}

class _ResultSheetView extends StatefulWidget {
  const _ResultSheetView({required this.kind});

  final ResultSheetKind kind;

  @override
  State<_ResultSheetView> createState() => _ResultSheetViewState();
}

class _ResultSheetViewState extends State<_ResultSheetView> {
  ResultSheetSort _sort = ResultSheetSort.rollNumber;

  @override
  Widget build(BuildContext context) {
    final isSection = widget.kind == ResultSheetKind.sectionSheet;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSection ? 'Section Result Sheet' : 'Class Result Sheet'),
        actions: [const DashboardNavigationButton(),
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
          ResultsFailure(:final message) => _SheetError(message: message),
          PublishedResultsLoaded() => _ResultSheetContent(
            data: state,
            kind: widget.kind,
            sort: _sort,
            onSortChanged: (value) => setState(() => _sort = value),
          ),
        },
      ),
    );
  }
}

class _ResultSheetContent extends StatelessWidget {
  const _ResultSheetContent({
    required this.data,
    required this.kind,
    required this.sort,
    required this.onSortChanged,
  });

  final PublishedResultsLoaded data;
  final ResultSheetKind kind;
  final ResultSheetSort sort;
  final ValueChanged<ResultSheetSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final isSection = kind == ResultSheetKind.sectionSheet;
    final selectionComplete =
        data.selectedAcademicSession != null &&
        data.selectedExamId != null &&
        data.selectedClassId != null &&
        (!isSection || data.selectedSectionId != null);
    final results = _sortResults(data.filteredResults, sort, kind);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (data.isLoading) const LinearProgressIndicator(),
            if (data.isLoading) const SizedBox(height: 12),
            PublishedResultsFilterCard(data: data, showSection: isSection),
            const SizedBox(height: 12),
            _SheetToolbar(
              count: selectionComplete ? results.length : 0,
              sort: sort,
              onSortChanged: onSortChanged,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ResultsExportActions(
                request: ResultExportRequestFactory.fromPublishedResults(
                  type: isSection
                      ? ResultExportType.sectionSheet
                      : ResultExportType.classSheet,
                  title: isSection
                      ? 'Section Result Sheet'
                      : 'Class Result Sheet',
                  results: selectionComplete ? results : const [],
                  data: data,
                  metrics: ResultExportRequestFactory.summaryMetrics(results),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: selectionComplete
                  ? _ResultSheetTable(results: results, kind: kind)
                  : _SelectionState(isSection: isSection),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetToolbar extends StatelessWidget {
  const _SheetToolbar({
    required this.count,
    required this.sort,
    required this.onSortChanged,
  });

  final int count;
  final ResultSheetSort sort;
  final ValueChanged<ResultSheetSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$count student${count == 1 ? '' : 's'}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<ResultSheetSort>(
            initialValue: sort,
            decoration: const InputDecoration(
              labelText: 'Sort by',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: ResultSheetSort.rollNumber,
                child: Text('Roll Number'),
              ),
              DropdownMenuItem(
                value: ResultSheetSort.name,
                child: Text('Student Name'),
              ),
              DropdownMenuItem(
                value: ResultSheetSort.percentage,
                child: Text('Percentage'),
              ),
              DropdownMenuItem(
                value: ResultSheetSort.position,
                child: Text('Position'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onSortChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _ResultSheetTable extends StatelessWidget {
  const _ResultSheetTable({required this.results, required this.kind});

  final List<ExamResultEntity> results;
  final ResultSheetKind kind;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const _EmptySheet(
        message: 'No published results match the selected filters.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _MobileSheetRow(result: results[index], kind: kind),
          );
        }
        return Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                columns: const [
                  DataColumn(label: Text('Roll No')),
                  DataColumn(label: Text('Admission No')),
                  DataColumn(label: Text('Student Name')),
                  DataColumn(label: Text('Obtained Marks')),
                  DataColumn(label: Text('Percentage')),
                  DataColumn(label: Text('Grade')),
                  DataColumn(label: Text('Position')),
                  DataColumn(label: Text('Pass / Fail')),
                ],
                rows: results
                    .map(
                      (result) => DataRow(
                        cells: [
                          DataCell(Text(_emptyAsDash(result.rollNumber))),
                          DataCell(Text(_emptyAsDash(result.admissionNo))),
                          DataCell(Text(result.studentName)),
                          DataCell(Text(_number(result.grandObtainedMarks))),
                          DataCell(
                            Text('${result.percentage.toStringAsFixed(1)}%'),
                          ),
                          DataCell(Text(result.grade)),
                          DataCell(Text('${_position(result, kind)}')),
                          DataCell(Text(result.isPassed ? 'Pass' : 'Fail')),
                        ],
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobileSheetRow extends StatelessWidget {
  const _MobileSheetRow({required this.result, required this.kind});

  final ExamResultEntity result;
  final ResultSheetKind kind;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.studentName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Roll: ${_emptyAsDash(result.rollNumber)} • Admission: ${_emptyAsDash(result.admissionNo)}',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _Value(
                  label: 'Obtained',
                  value: _number(result.grandObtainedMarks),
                ),
                _Value(
                  label: 'Percentage',
                  value: '${result.percentage.toStringAsFixed(1)}%',
                ),
                _Value(label: 'Grade', value: result.grade),
                _Value(label: 'Position', value: '${_position(result, kind)}'),
                _Value(
                  label: 'Result',
                  value: result.isPassed ? 'Pass' : 'Fail',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      Text(value),
    ],
  );
}

class _SelectionState extends StatelessWidget {
  const _SelectionState({required this.isSection});

  final bool isSection;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        isSection
            ? 'Select academic session, exam, class, and section to view the result sheet.'
            : 'Select academic session, exam, and class to view the result sheet.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _EmptySheet extends StatelessWidget {
  const _EmptySheet({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

class _SheetError extends StatelessWidget {
  const _SheetError({required this.message});

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

enum ResultSheetSort { rollNumber, name, percentage, position }

List<ExamResultEntity> _sortResults(
  List<ExamResultEntity> results,
  ResultSheetSort sort,
  ResultSheetKind kind,
) {
  final values = [...results];
  values.sort((first, second) {
    return switch (sort) {
      ResultSheetSort.rollNumber => _rollOrder(first, second),
      ResultSheetSort.name => first.studentName.compareTo(second.studentName),
      ResultSheetSort.percentage => second.percentage.compareTo(
        first.percentage,
      ),
      ResultSheetSort.position => _position(
        first,
        kind,
      ).compareTo(_position(second, kind)),
    };
  });
  return values;
}

int _position(ExamResultEntity result, ResultSheetKind kind) =>
    kind == ResultSheetKind.classSheet
    ? result.classPosition
    : result.sectionPosition;

int _rollOrder(ExamResultEntity first, ExamResultEntity second) {
  final firstValue = int.tryParse(first.rollNumber.trim());
  final secondValue = int.tryParse(second.rollNumber.trim());
  if (firstValue != null && secondValue != null) {
    return firstValue.compareTo(secondValue);
  }
  if (firstValue != null) return -1;
  if (secondValue != null) return 1;
  return first.rollNumber.compareTo(second.rollNumber);
}

String _emptyAsDash(String value) => value.trim().isEmpty ? '-' : value;

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
