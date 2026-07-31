import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/results_bloc.dart';
import '../bloc/results_event.dart';
import '../bloc/results_state.dart';

class PublishedResultsFilterCard extends StatefulWidget {
  const PublishedResultsFilterCard({
    required this.data,
    this.includeStudent = false,
    this.showSection = true,
    this.searchLabel = 'Search name, admission no or roll no',
    super.key,
  });

  final PublishedResultsLoaded data;
  final bool includeStudent;
  final bool showSection;
  final String searchLabel;

  @override
  State<PublishedResultsFilterCard> createState() =>
      _PublishedResultsFilterCardState();
}

class _PublishedResultsFilterCardState
    extends State<PublishedResultsFilterCard> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.data.searchQuery);
  }

  @override
  void didUpdateWidget(covariant PublishedResultsFilterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = widget.data.searchQuery;
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
    final bloc = context.read<ResultsBloc>();
    final data = widget.data;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final searchWidth = constraints.maxWidth < 320
                ? constraints.maxWidth
                : 320.0;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
            ResultFilterSelect(
              label: 'Academic Session',
              value: data.selectedAcademicSession,
              items: data.availableSessions
                  .map((value) => ResultFilterOption(value, value))
                  .toList(growable: false),
              onChanged: (value) => bloc.add(FilterResultsBySession(value)),
            ),
            ResultFilterSelect(
              label: 'Exam',
              value: data.selectedExamId,
              items: data.availableExams
                  .map(
                    (result) =>
                        ResultFilterOption(result.examId, result.examName),
                  )
                  .toList(growable: false),
              onChanged: (value) => bloc.add(FilterResultsByExam(value)),
            ),
            ResultFilterSelect(
              label: 'Class',
              value: data.selectedClassId,
              items: data.availableClasses
                  .map(
                    (result) =>
                        ResultFilterOption(result.classId, result.className),
                  )
                  .toList(growable: false),
              onChanged: (value) => bloc.add(FilterResultsByClass(value)),
            ),
            if (widget.showSection)
              ResultFilterSelect(
                label: 'Section',
                value: data.selectedSectionId,
                enabled: data.selectedClassId != null,
                items: data.availableSections
                    .map(
                      (result) => ResultFilterOption(
                        result.sectionId,
                        result.sectionName,
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => bloc.add(FilterResultsBySection(value)),
              ),
            if (widget.includeStudent)
              ResultFilterSelect(
                label: 'Student',
                value: data.selectedStudentId,
                items: data.availableStudents
                    .map(
                      (result) => ResultFilterOption(
                        result.studentId,
                        '${result.studentName} (${_rollNumber(result.rollNumber)})',
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => bloc.add(FilterResultsByStudent(value)),
              ),
            SizedBox(
              width: searchWidth,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => bloc.add(SearchPublishedResults(value)),
                decoration: InputDecoration(
                  labelText: widget.searchLabel,
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

class ResultFilterSelect extends StatelessWidget {
  const ResultFilterSelect({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String? value;
  final List<ResultFilterOption> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: DropdownButtonFormField<String>(
        value: items.any((item) => item.id == value) ? value : null,
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

class ResultFilterOption {
  const ResultFilterOption(this.id, this.label);

  final String id;
  final String label;
}

String _rollNumber(String value) => value.trim().isEmpty ? '-' : value;
