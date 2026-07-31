import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../domain/entities/result_export_request.dart';
import '../bloc/result_archive_bloc.dart';
import '../bloc/result_archive_event.dart';
import '../bloc/result_archive_state.dart';
import '../widgets/result_export_request_factory.dart';
import '../widgets/results_export_actions.dart';
import 'individual_report_card_page.dart';

class ResultArchivePage extends StatelessWidget {
  const ResultArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResultArchiveBloc>()..add(const LoadResultArchive()),
      child: const _ResultArchiveView(),
    );
  }
}

class _ResultArchiveView extends StatelessWidget {
  const _ResultArchiveView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result Archive'),
        actions: [
          IconButton(
            tooltip: 'Refresh archive',
            onPressed: () => context.read<ResultArchiveBloc>().add(
              const RefreshResultArchive(),
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<ResultArchiveBloc, ResultArchiveState>(
        builder: (context, state) => switch (state) {
          ResultArchiveInitial() || ResultArchiveLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          ResultArchiveFailure(:final message) => _ArchiveError(
            message: message,
          ),
          ResultArchiveLoaded() => _ArchiveContent(data: state),
        },
      ),
    );
  }
}

class _ArchiveContent extends StatelessWidget {
  const _ArchiveContent({required this.data});

  final ResultArchiveLoaded data;

  @override
  Widget build(BuildContext context) {
    final results = data.filteredResults;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (data.isRefreshing) const LinearProgressIndicator(),
            if (data.isRefreshing) const SizedBox(height: 12),
            _ArchiveFilters(data: data),
            const SizedBox(height: 12),
            _ArchiveToolbar(data: data, results: results),
            const SizedBox(height: 12),
            Expanded(
              child: results.isEmpty
                  ? const _ArchiveEmpty()
                  : _ArchiveResultsTable(results: results),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveFilters extends StatelessWidget {
  const _ArchiveFilters({required this.data});

  final ResultArchiveLoaded data;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ResultArchiveBloc>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 1120 ? 230.0 : 280.0;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search archive',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => bloc.add(SearchResultArchive(value)),
                  ),
                ),
                _ArchiveSelect(
                  width: width,
                  label: 'Academic Session',
                  value: data.academicSession,
                  items: data.sessions.map(
                    (value) => _ArchiveOption(value, value),
                  ),
                  onChanged: (value) => bloc.add(FilterArchiveBySession(value)),
                ),
                _ArchiveSelect(
                  width: width,
                  label: 'Exam',
                  value: data.examId,
                  items: data.exams.map(
                    (value) => _ArchiveOption(value.examId, value.examName),
                  ),
                  onChanged: (value) => bloc.add(FilterArchiveByExam(value)),
                ),
                _ArchiveSelect(
                  width: width,
                  label: 'Class',
                  value: data.classId,
                  items: data.classes.map(
                    (value) => _ArchiveOption(value.classId, value.className),
                  ),
                  onChanged: (value) => bloc.add(FilterArchiveByClass(value)),
                ),
                _ArchiveSelect(
                  width: width,
                  label: 'Section',
                  value: data.sectionId,
                  items: data.sections.map(
                    (value) =>
                        _ArchiveOption(value.sectionId, value.sectionName),
                  ),
                  onChanged: (value) => bloc.add(FilterArchiveBySection(value)),
                ),
                _ArchiveSelect(
                  width: width,
                  label: 'Student',
                  value: data.studentId,
                  items: data.students.map(
                    (value) =>
                        _ArchiveOption(value.studentId, value.studentName),
                  ),
                  onChanged: (value) => bloc.add(FilterArchiveByStudent(value)),
                ),
                SizedBox(
                  width: width,
                  child: DropdownButtonFormField<ResultStatus>(
                    initialValue: data.status,
                    decoration: const InputDecoration(
                      labelText: 'Result Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All published records'),
                      ),
                      DropdownMenuItem(
                        value: ResultStatus.published,
                        child: Text('Published'),
                      ),
                      DropdownMenuItem(
                        value: ResultStatus.locked,
                        child: Text('Locked'),
                      ),
                    ],
                    onChanged: (value) =>
                        bloc.add(FilterArchiveByStatus(value)),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _selectDates(context, bloc, data.publicationRange),
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(_dateRangeLabel(data.publicationRange)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectDates(
    BuildContext context,
    ResultArchiveBloc bloc,
    DateTimeRange? current,
  ) async {
    final today = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 2),
      initialDateRange: current,
    );
    if (range != null) bloc.add(FilterArchiveByPublicationDates(range));
  }
}

class _ArchiveSelect extends StatelessWidget {
  const _ArchiveSelect({
    required this.width,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final double width;
  final String label;
  final String? value;
  final Iterable<_ArchiveOption> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('All')),
        ...items.map(
          (item) => DropdownMenuItem(value: item.id, child: Text(item.label)),
        ),
      ],
      onChanged: onChanged,
    ),
  );
}

class _ArchiveOption {
  const _ArchiveOption(this.id, this.label);

  final String id;
  final String label;
}

class _ArchiveToolbar extends StatelessWidget {
  const _ArchiveToolbar({required this.data, required this.results});

  final ResultArchiveLoaded data;
  final List<ExamResultEntity> results;

  @override
  Widget build(BuildContext context) {
    final filters = {
      'Academic Session': data.academicSession ?? '',
      'Exam': _label(
        data.exams,
        data.examId,
        (item) => item.examId,
        (item) => item.examName,
      ),
      'Class': _label(
        data.classes,
        data.classId,
        (item) => item.classId,
        (item) => item.className,
      ),
      'Section': _label(
        data.sections,
        data.sectionId,
        (item) => item.sectionId,
        (item) => item.sectionName,
      ),
      'Student': _label(
        data.students,
        data.studentId,
        (item) => item.studentId,
        (item) => item.studentName,
      ),
      'Published Date': _dateRangeLabel(data.publicationRange),
    };
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        Text(
          '${results.length} archived published result${results.length == 1 ? '' : 's'}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        ResultsExportActions(
          request: ResultExportRequestFactory.fromArchive(
            title: 'Result Archive',
            results: results,
            filters: filters,
            type: ResultExportType.gazette,
            metrics: ResultExportRequestFactory.summaryMetrics(results),
          ),
        ),
      ],
    );
  }
}

class _ArchiveResultsTable extends StatelessWidget {
  const _ArchiveResultsTable({required this.results});

  final List<ExamResultEntity> results;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _ArchiveMobileRow(result: results[index]),
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
                  DataColumn(label: Text('Published')),
                  DataColumn(label: Text('Session')),
                  DataColumn(label: Text('Exam')),
                  DataColumn(label: Text('Student')),
                  DataColumn(label: Text('Class / Section')),
                  DataColumn(label: Text('%')),
                  DataColumn(label: Text('Grade')),
                  DataColumn(label: Text('Result')),
                  DataColumn(label: Text('Open')),
                ],
                rows: results
                    .map((result) => _archiveRow(context, result))
                    .toList(growable: false),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _archiveRow(BuildContext context, ExamResultEntity result) => DataRow(
    cells: [
      DataCell(Text(_shortDate(result.publishedAt ?? result.updatedAt))),
      DataCell(Text(result.academicSession)),
      DataCell(Text(result.examName)),
      DataCell(Text(result.studentName)),
      DataCell(Text('${result.className} - ${result.sectionName}')),
      DataCell(Text('${result.percentage.toStringAsFixed(1)}%')),
      DataCell(Text(result.grade)),
      DataCell(Text(result.isPassed ? 'Pass' : 'Fail')),
      DataCell(
        IconButton(
          tooltip: 'Open report card',
          icon: const Icon(Icons.open_in_new),
          onPressed: () => _open(context, result),
        ),
      ),
    ],
  );

  void _open(BuildContext context, ExamResultEntity result) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IndividualReportCardPage(result: result),
      ),
    );
  }
}

class _ArchiveMobileRow extends StatelessWidget {
  const _ArchiveMobileRow({required this.result});

  final ExamResultEntity result;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(result.studentName),
      subtitle: Text(
        '${result.examName} • ${result.academicSession}\n'
        '${result.className}-${result.sectionName} • ${result.percentage.toStringAsFixed(1)}% • ${result.grade}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.open_in_new),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => IndividualReportCardPage(result: result),
        ),
      ),
    ),
  );
}

class _ArchiveEmpty extends StatelessWidget {
  const _ArchiveEmpty();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'No published or locked results match these archive filters.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _ArchiveError extends StatelessWidget {
  const _ArchiveError({required this.message});

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
            onPressed: () => context.read<ResultArchiveBloc>().add(
              const LoadResultArchive(),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    ),
  );
}

String _label(
  List<ExamResultEntity> values,
  String? selectedId,
  String Function(ExamResultEntity) id,
  String Function(ExamResultEntity) label,
) {
  if (selectedId == null) return '';
  for (final item in values) {
    if (id(item) == selectedId) return label(item);
  }
  return '';
}

String _dateRangeLabel(DateTimeRange? range) {
  if (range == null) return 'Publication date';
  return '${_shortDate(range.start)} - ${_shortDate(range.end)}';
}

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
