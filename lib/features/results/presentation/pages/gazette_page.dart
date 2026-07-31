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

class GazettePage extends StatelessWidget {
  const GazettePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResultsBloc>()..add(const LoadPublishedResults()),
      child: const _GazetteView(),
    );
  }
}

class _GazetteView extends StatelessWidget {
  const _GazetteView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gazette'),
        actions: [
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
          ResultsFailure(:final message) => _GazetteError(message: message),
          PublishedResultsLoaded() => _GazetteContent(data: state),
        },
      ),
    );
  }
}

class _GazetteContent extends StatelessWidget {
  const _GazetteContent({required this.data});

  final PublishedResultsLoaded data;

  @override
  Widget build(BuildContext context) {
    final ready =
        data.selectedAcademicSession != null && data.selectedExamId != null;
    final rows = _gazetteRows(data.filteredResults);
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
            Expanded(
              child: ready
                  ? _GazetteDocument(rows: rows, data: data)
                  : const _GazetteSelectionHint(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GazetteDocument extends StatelessWidget {
  const _GazetteDocument({required this.rows, required this.data});

  final List<ExamResultEntity> rows;
  final PublishedResultsLoaded data;

  @override
  Widget build(BuildContext context) {
    final heading = [
      data.selectedAcademicSession,
      data.availableExams
          .where((exam) => exam.examId == data.selectedExamId)
          .map((exam) => exam.examName)
          .letFirstOrNull(),
      data.availableClasses
          .where((item) => item.classId == data.selectedClassId)
          .map((item) => item.className)
          .letFirstOrNull(),
      data.availableSections
          .where((item) => item.sectionId == data.selectedSectionId)
          .map((item) => item.sectionName)
          .letFirstOrNull(),
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GazetteHeader(subtitle: heading),
            Align(
              alignment: Alignment.centerRight,
              child: ResultsExportActions(
                request: ResultExportRequestFactory.fromPublishedResults(
                  type: ResultExportType.gazette,
                  title: 'Result Gazette',
                  results: rows,
                  data: data,
                  metrics: ResultExportRequestFactory.summaryMetrics(rows),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No published results match the selected filters.',
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  columns: const [
                    DataColumn(label: Text('Roll')),
                    DataColumn(label: Text('Admission No')),
                    DataColumn(label: Text('Student Name')),
                    DataColumn(label: Text('Class')),
                    DataColumn(label: Text('Section')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Obtained')),
                    DataColumn(label: Text('%')),
                    DataColumn(label: Text('Grade')),
                    DataColumn(label: Text('Position')),
                    DataColumn(label: Text('Result')),
                  ],
                  rows: rows
                      .map(
                        (result) => DataRow(
                          cells: [
                            DataCell(Text(_dash(result.rollNumber))),
                            DataCell(Text(_dash(result.admissionNo))),
                            DataCell(Text(result.studentName)),
                            DataCell(Text(result.className)),
                            DataCell(Text(result.sectionName)),
                            DataCell(Text(_number(result.grandTotalMarks))),
                            DataCell(Text(_number(result.grandObtainedMarks))),
                            DataCell(
                              Text('${result.percentage.toStringAsFixed(1)}%'),
                            ),
                            DataCell(Text(result.grade)),
                            DataCell(Text('${result.sectionPosition}')),
                            DataCell(Text(result.isPassed ? 'Pass' : 'Fail')),
                          ],
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Published results only • Read-only gazette',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GazetteHeader extends StatelessWidget {
  const _GazetteHeader({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/logo.jpeg',
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.school_outlined),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Almustafa Model School',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                'RESULT GAZETTE',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GazetteSelectionHint extends StatelessWidget {
  const _GazetteSelectionHint();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Select academic session and exam to view the published gazette.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _GazetteError extends StatelessWidget {
  const _GazetteError({required this.message});

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

List<ExamResultEntity> _gazetteRows(List<ExamResultEntity> values) {
  final rows = [...values];
  rows.sort((first, second) {
    final classOrder = first.className.compareTo(second.className);
    if (classOrder != 0) return classOrder;
    final sectionOrder = first.sectionName.compareTo(second.sectionName);
    if (sectionOrder != 0) return sectionOrder;
    final firstRoll = int.tryParse(first.rollNumber.trim());
    final secondRoll = int.tryParse(second.rollNumber.trim());
    if (firstRoll != null && secondRoll != null) {
      return firstRoll.compareTo(secondRoll);
    }
    return first.studentName.compareTo(second.studentName);
  });
  return rows;
}

String _dash(String value) => value.trim().isEmpty ? '-' : value;

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? letFirstOrNull() {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
