import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/presentation/widgets/result_status_chip.dart';
import '../bloc/results_bloc.dart';
import '../bloc/results_event.dart';
import '../bloc/results_state.dart';
import 'result_sheet_page.dart';
import 'student_result_details_page.dart';

enum ResultsViewType { studentResults, classResults, sectionResults }

class PublishedResultsPage extends StatelessWidget {
  const PublishedResultsPage({required this.type, super.key});

  final ResultsViewType type;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResultsBloc>()..add(const LoadPublishedResults()),
      child: _PublishedResultsView(type: type),
    );
  }
}

class _PublishedResultsView extends StatefulWidget {
  const _PublishedResultsView({required this.type});

  final ResultsViewType type;

  @override
  State<_PublishedResultsView> createState() => _PublishedResultsViewState();
}

class _PublishedResultsViewState extends State<_PublishedResultsView> {
  ResultSort _sort = ResultSort.rank;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title(widget.type)),
        actions: [
          const DashboardNavigationButton(),
          if (widget.type != ResultsViewType.studentResults)
            IconButton(
              tooltip: 'Open result sheet',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ResultSheetPage(
                    kind: widget.type == ResultsViewType.classResults
                        ? ResultSheetKind.classSheet
                        : ResultSheetKind.sectionSheet,
                  ),
                ),
              ),
              icon: const Icon(Icons.table_chart_outlined),
            ),
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
        builder: (context, state) {
          return switch (state) {
            ResultsInitial() || ResultsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ResultsFailure(:final message) => _FailureView(message: message),
            PublishedResultsLoaded() => _ResultsContent(
              type: widget.type,
              data: state,
              sort: _sort,
              onSortChanged: (value) => setState(() => _sort = value),
            ),
          };
        },
      ),
    );
  }
}

class _ResultsContent extends StatelessWidget {
  const _ResultsContent({
    required this.type,
    required this.data,
    required this.sort,
    required this.onSortChanged,
  });

  final ResultsViewType type;
  final PublishedResultsLoaded data;
  final ResultSort sort;
  final ValueChanged<ResultSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final rows = _sorted(data.filteredResults, sort);
    final filtersComplete = _requiredFiltersAreSelected(type, data);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (data.isLoading) const LinearProgressIndicator(),
            if (data.isLoading) const SizedBox(height: 12),
            _PublishedResultsFilters(type: type, data: data),
            const SizedBox(height: 12),
            _ResultListToolbar(
              count: filtersComplete ? rows.length : 0,
              sort: sort,
              onSortChanged: onSortChanged,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtersComplete
                  ? _ResultsTable(results: rows)
                  : _SelectionRequiredView(type: type),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublishedResultsFilters extends StatefulWidget {
  const _PublishedResultsFilters({required this.type, required this.data});

  final ResultsViewType type;
  final PublishedResultsLoaded data;

  @override
  State<_PublishedResultsFilters> createState() =>
      _PublishedResultsFiltersState();
}

class _PublishedResultsFiltersState extends State<_PublishedResultsFilters> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.data.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _PublishedResultsFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.data.searchQuery) {
      _searchController.value = _searchController.value.copyWith(
        text: widget.data.searchQuery,
        selection: TextSelection.collapsed(
          offset: widget.data.searchQuery.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ResultsBloc>();
    final data = widget.data;
    final showStudentFilter = widget.type == ResultsViewType.studentResults;
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterSelect(
                label: 'Academic Session',
                value: data.selectedAcademicSession,
                items: data.availableSessions
                    .map((value) => _SelectItem(value, value))
                    .toList(growable: false),
                onChanged: (value) => bloc.add(FilterResultsBySession(value)),
              ),
              const SizedBox(width: 8),
              _FilterSelect(
                label: 'Exam',
                value: data.selectedExamId,
                items: data.availableExams
                    .map(
                      (result) => _SelectItem(result.examId, result.examName),
                    )
                    .toList(growable: false),
                onChanged: (value) => bloc.add(FilterResultsByExam(value)),
              ),
              const SizedBox(width: 8),
              _FilterSelect(
                label: 'Class',
                value: data.selectedClassId,
                items: data.availableClasses
                    .map(
                      (result) => _SelectItem(result.classId, result.className),
                    )
                    .toList(growable: false),
                onChanged: (value) => bloc.add(FilterResultsByClass(value)),
              ),
              const SizedBox(width: 8),
              _FilterSelect(
                label: 'Section',
                value: data.selectedSectionId,
                enabled: data.selectedClassId != null,
                items: data.availableSections
                    .map(
                      (result) =>
                          _SelectItem(result.sectionId, result.sectionName),
                    )
                    .toList(growable: false),
                onChanged: (value) => bloc.add(FilterResultsBySection(value)),
              ),
              if (showStudentFilter) const SizedBox(width: 8),
              if (showStudentFilter)
                _FilterSelect(
                  label: 'Student',
                  value: data.selectedStudentId,
                  items: data.availableStudents
                      .map(
                        (result) => _SelectItem(
                          result.studentId,
                          '${result.studentName} (${_roll(result)})',
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => bloc.add(FilterResultsByStudent(value)),
                ),
              const SizedBox(width: 8),
              SizedBox(
                width: compact ? 220 : 320,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => bloc.add(SearchPublishedResults(value)),
                  decoration: InputDecoration(
                    labelText: 'Search name, admission no or roll no',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              bloc.add(const SearchPublishedResults(''));
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Chip(
                avatar: Icon(Icons.visibility_outlined, size: 16),
                label: Text('Published results only'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultListToolbar extends StatelessWidget {
  const _ResultListToolbar({
    required this.count,
    required this.sort,
    required this.onSortChanged,
  });

  final int count;
  final ResultSort sort;
  final ValueChanged<ResultSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$count published result${count == 1 ? '' : 's'}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<ResultSort>(
            initialValue: sort,
            decoration: const InputDecoration(
              labelText: 'Sort by',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: ResultSort.rank,
                child: Text('Overall Rank'),
              ),
              DropdownMenuItem(
                value: ResultSort.name,
                child: Text('Student Name'),
              ),
              DropdownMenuItem(
                value: ResultSort.percentage,
                child: Text('Percentage'),
              ),
              DropdownMenuItem(
                value: ResultSort.rollNumber,
                child: Text('Roll Number'),
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

class _ResultsTable extends StatelessWidget {
  const _ResultsTable({required this.results});

  final List<ExamResultEntity> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const _EmptyView(
        message: 'No published results match the selected filters.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 880) {
          return ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _MobileResultCard(result: results[index]),
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
    const rollWidth = 72.0;
    const marksWidth = 95.0;
    const percentageWidth = 94.0;
    const gradeWidth = 70.0;
    const rankWidth = 72.0;
    const statusWidth = 118.0;
    const actionWidth = 66.0;
    const horizontalPadding = 32.0;
    const fixedWidth =
        horizontalPadding +
        rollWidth +
        marksWidth * 2 +
        percentageWidth +
        gradeWidth +
        rankWidth +
        statusWidth +
        actionWidth;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final studentWidth = (constraints.maxWidth - fixedWidth)
              .clamp(220.0, double.infinity)
              .toDouble();
          return Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: rollWidth, child: _Header('Roll')),
                    SizedBox(
                      width: studentWidth,
                      child: const _Header('Student'),
                    ),
                    const SizedBox(width: marksWidth, child: _Header('Total')),
                    const SizedBox(
                      width: marksWidth,
                      child: _Header('Obtained'),
                    ),
                    const SizedBox(width: percentageWidth, child: _Header('%')),
                    const SizedBox(width: gradeWidth, child: _Header('Grade')),
                    const SizedBox(width: rankWidth, child: _Header('Rank')),
                    const SizedBox(
                      width: statusWidth,
                      child: _Header('Status'),
                    ),
                    const SizedBox(width: actionWidth),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: rollWidth,
                            child: Text(_roll(result)),
                          ),
                          SizedBox(
                            width: studentWidth,
                            child: _StudentCell(result: result),
                          ),
                          SizedBox(
                            width: marksWidth,
                            child: Text(_number(result.grandTotalMarks)),
                          ),
                          SizedBox(
                            width: marksWidth,
                            child: Text(_number(result.grandObtainedMarks)),
                          ),
                          SizedBox(
                            width: percentageWidth,
                            child: Text(_percentage(result.percentage)),
                          ),
                          SizedBox(
                            width: gradeWidth,
                            child: Text(result.grade),
                          ),
                          SizedBox(
                            width: rankWidth,
                            child: Text('${result.overallRank}'),
                          ),
                          SizedBox(
                            width: statusWidth,
                            child: ResultStatusChip(status: result.status),
                          ),
                          SizedBox(
                            width: actionWidth,
                            child: IconButton(
                              tooltip: 'Open result',
                              onPressed: () => _openDetails(context, result),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                          ),
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
      child: InkWell(
        onTap: () => _openDetails(context, result),
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
              const SizedBox(height: 10),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  _Detail(
                    label: 'Total',
                    value: _number(result.grandTotalMarks),
                  ),
                  _Detail(
                    label: 'Obtained',
                    value: _number(result.grandObtainedMarks),
                  ),
                  _Detail(
                    label: 'Percentage',
                    value: _percentage(result.percentage),
                  ),
                  _Detail(label: 'Grade', value: result.grade),
                  _Detail(label: 'Rank', value: '${result.overallRank}'),
                  _Detail(
                    label: 'Result',
                    value: result.isPassed ? 'Pass' : 'Fail',
                  ),
                ],
              ),
            ],
          ),
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(result.studentName, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(
          '${result.examName} • ${result.className}-${result.sectionName} • ${result.admissionNo}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _FilterSelect extends StatelessWidget {
  const _FilterSelect({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final List<_SelectItem> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return SizedBox(
      width: compact ? 150 : 230,
      child: DropdownButtonFormField<String>(
        initialValue: items.any((item) => item.id == value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
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

class _Header extends StatelessWidget {
  const _Header(this.value);

  final String value;

  @override
  Widget build(BuildContext context) =>
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700));
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fact_check_outlined,
            size: 46,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SelectionRequiredView extends StatelessWidget {
  const _SelectionRequiredView({required this.type});

  final ResultsViewType type;

  @override
  Widget build(BuildContext context) {
    final message = switch (type) {
      ResultsViewType.studentResults => '',
      ResultsViewType.classResults =>
        'Select academic session, exam, and class to view the complete class result.',
      ResultsViewType.sectionResults =>
        'Select academic session, exam, class, and section to view the section result.',
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt_outlined,
              size: 46,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
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
              onPressed: () =>
                  context.read<ResultsBloc>().add(const LoadPublishedResults()),
              child: const Text('Try Again'),
            ),
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

enum ResultSort { rank, name, percentage, rollNumber }

List<ExamResultEntity> _sorted(
  List<ExamResultEntity> results,
  ResultSort sort,
) {
  final values = [...results];
  values.sort((first, second) {
    return switch (sort) {
      ResultSort.rank => first.overallRank.compareTo(second.overallRank),
      ResultSort.name => first.studentName.compareTo(second.studentName),
      ResultSort.percentage => second.percentage.compareTo(first.percentage),
      ResultSort.rollNumber => _rollOrder(first, second),
    };
  });
  return values;
}

int _rollOrder(ExamResultEntity first, ExamResultEntity second) {
  final firstRoll = int.tryParse(first.rollNumber.trim());
  final secondRoll = int.tryParse(second.rollNumber.trim());
  if (firstRoll != null && secondRoll != null) {
    return firstRoll.compareTo(secondRoll);
  }
  if (firstRoll != null) return -1;
  if (secondRoll != null) return 1;
  return first.rollNumber.compareTo(second.rollNumber);
}

void _openDetails(BuildContext context, ExamResultEntity result) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => StudentResultDetailsPage(result: result),
    ),
  );
}

String _title(ResultsViewType type) => switch (type) {
  ResultsViewType.studentResults => 'Student Results',
  ResultsViewType.classResults => 'Class Results',
  ResultsViewType.sectionResults => 'Section Results',
};

bool _requiredFiltersAreSelected(
  ResultsViewType type,
  PublishedResultsLoaded data,
) {
  return switch (type) {
    ResultsViewType.studentResults => true,
    ResultsViewType.classResults =>
      data.selectedAcademicSession != null &&
          data.selectedExamId != null &&
          data.selectedClassId != null,
    ResultsViewType.sectionResults =>
      data.selectedAcademicSession != null &&
          data.selectedExamId != null &&
          data.selectedClassId != null &&
          data.selectedSectionId != null,
  };
}

String _roll(ExamResultEntity result) =>
    result.rollNumber.trim().isEmpty ? '-' : result.rollNumber;
String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
String _percentage(double value) => '${value.toStringAsFixed(1)}%';
