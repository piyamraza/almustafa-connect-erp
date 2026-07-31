import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/result_analytics_entity.dart';
import '../bloc/results_analytics_bloc.dart';
import '../bloc/results_analytics_event.dart';
import '../bloc/results_analytics_state.dart';

class ResultsAnalyticsFilterCard extends StatefulWidget {
  const ResultsAnalyticsFilterCard({
    required this.data,
    this.showSubject = false,
    this.showStudent = false,
    this.showSection = true,
    this.showSearch = false,
    this.showSort = false,
    this.showRiskThresholds = false,
    super.key,
  });

  final ResultsAnalyticsLoaded data;
  final bool showSubject;
  final bool showStudent;
  final bool showSection;
  final bool showSearch;
  final bool showSort;
  final bool showRiskThresholds;

  @override
  State<ResultsAnalyticsFilterCard> createState() =>
      _ResultsAnalyticsFilterCardState();
}

class _ResultsAnalyticsFilterCardState
    extends State<ResultsAnalyticsFilterCard> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.data.filter.searchQuery,
    );
  }

  @override
  void didUpdateWidget(covariant ResultsAnalyticsFilterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = widget.data.filter.searchQuery;
    if (_searchController.text != query) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
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
    final data = widget.data;
    final bloc = context.read<ResultsAnalyticsBloc>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth < 250
                ? constraints.maxWidth
                : 230.0;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _AnalyticsSelect(
                  label: 'Academic Session',
                  value: data.filter.academicSession,
                  items: data.availableSessions
                      .map((value) => _AnalyticsOption(value, value))
                      .toList(growable: false),
                  onChanged: (value) =>
                      bloc.add(FilterAnalyticsBySession(value)),
                  width: fieldWidth,
                ),
                _AnalyticsSelect(
                  label: 'Exam',
                  value: data.filter.examId,
                  items: data.availableExams
                      .map(
                        (value) =>
                            _AnalyticsOption(value.examId, value.examName),
                      )
                      .toList(growable: false),
                  onChanged: (value) => bloc.add(FilterAnalyticsByExam(value)),
                  width: fieldWidth,
                ),
                _AnalyticsSelect(
                  label: 'Class',
                  value: data.filter.classId,
                  items: data.availableClasses
                      .map(
                        (value) =>
                            _AnalyticsOption(value.classId, value.className),
                      )
                      .toList(growable: false),
                  onChanged: (value) => bloc.add(FilterAnalyticsByClass(value)),
                  width: fieldWidth,
                ),
                if (widget.showSection)
                  _AnalyticsSelect(
                    label: 'Section',
                    value: data.filter.sectionId,
                    enabled: data.filter.classId != null,
                    items: data.availableSections
                        .map(
                          (value) => _AnalyticsOption(
                            value.sectionId,
                            value.sectionName,
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) =>
                        bloc.add(FilterAnalyticsBySection(value)),
                    width: fieldWidth,
                  ),
                if (widget.showSubject)
                  _AnalyticsSelect(
                    label: 'Subject',
                    value: data.filter.subjectName,
                    items: data.availableSubjects
                        .map((value) => _AnalyticsOption(value, value))
                        .toList(growable: false),
                    onChanged: (value) =>
                        bloc.add(FilterAnalyticsBySubject(value)),
                    width: fieldWidth,
                  ),
                if (widget.showStudent)
                  _AnalyticsSelect(
                    label: 'Student',
                    value: data.filter.studentId,
                    items: data.availableStudents
                        .map(
                          (value) => _AnalyticsOption(
                            value.studentId,
                            '${value.studentName} (${_displayRoll(value.rollNumber)})',
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) =>
                        bloc.add(FilterAnalyticsByStudent(value)),
                    width: fieldWidth,
                  ),
                if (widget.showSearch)
                  SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          bloc.add(SearchAnalyticsStudents(value)),
                      decoration: InputDecoration(
                        labelText: 'Search student',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  bloc.add(const SearchAnalyticsStudents(''));
                                },
                                icon: const Icon(Icons.clear),
                              ),
                      ),
                    ),
                  ),
                if (widget.showSort)
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<AnalyticsSort>(
                      initialValue: data.filter.sort,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sort students',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AnalyticsSort.marksDescending,
                          child: Text('Highest marks first'),
                        ),
                        DropdownMenuItem(
                          value: AnalyticsSort.marksAscending,
                          child: Text('Lowest marks first'),
                        ),
                        DropdownMenuItem(
                          value: AnalyticsSort.nameAscending,
                          child: Text('Student name'),
                        ),
                        DropdownMenuItem(
                          value: AnalyticsSort.passFirst,
                          child: Text('Pass status first'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          bloc.add(SortAnalyticsSubjectRows(value));
                        }
                      },
                    ),
                  ),
                if (widget.showRiskThresholds)
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<double>(
                      initialValue: data.filter.borderlineMargin,
                      decoration: const InputDecoration(
                        labelText: 'Borderline margin (marks)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 3.0, child: Text('3 marks')),
                        DropdownMenuItem(value: 5.0, child: Text('5 marks')),
                        DropdownMenuItem(value: 7.0, child: Text('7 marks')),
                        DropdownMenuItem(value: 10.0, child: Text('10 marks')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          bloc.add(SetAnalyticsBorderlineMargin(value));
                        }
                      },
                    ),
                  ),
                if (widget.showRiskThresholds)
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<double>(
                      initialValue: data.filter.lowPerformanceThreshold,
                      decoration: const InputDecoration(
                        labelText: 'Low-performance threshold',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 33.0, child: Text('Below 33%')),
                        DropdownMenuItem(value: 40.0, child: Text('Below 40%')),
                        DropdownMenuItem(value: 50.0, child: Text('Below 50%')),
                        DropdownMenuItem(value: 60.0, child: Text('Below 60%')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          bloc.add(SetAnalyticsLowPerformanceThreshold(value));
                        }
                      },
                    ),
                  ),
                const Chip(
                  avatar: Icon(Icons.visibility_outlined, size: 16),
                  label: Text('Published results only'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnalyticsSelect extends StatelessWidget {
  const _AnalyticsSelect({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final List<_AnalyticsOption> items;
  final ValueChanged<String?> onChanged;
  final double width;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
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

class _AnalyticsOption {
  const _AnalyticsOption(this.id, this.label);

  final String id;
  final String label;
}

String _displayRoll(String roll) => roll.trim().isEmpty ? '-' : roll;
