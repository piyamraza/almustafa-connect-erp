import 'package:flutter/material.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/domain/services/result_subject_grouping_service.dart';

class GroupedSubjectResultsTable extends StatelessWidget {
  const GroupedSubjectResultsTable({
    required this.subjects,
    this.showRemarks = true,
    super.key,
  });

  final List<SubjectResultEntity> subjects;
  final bool showRemarks;

  @override
  Widget build(BuildContext context) {
    final rows = ResultSubjectGroupingService.group(subjects);
    if (rows.isEmpty) {
      return const Text('No subject details are available for this result.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        columns: [
          const DataColumn(label: Text('Subject')),
          const DataColumn(label: Text('Components')),
          const DataColumn(label: Text('Total')),
          const DataColumn(label: Text('Percentage')),
          const DataColumn(label: Text('Grade')),
          const DataColumn(label: Text('Status')),
          if (showRemarks) const DataColumn(label: Text('Teacher Remarks')),
        ],
        rows: rows
            .map((row) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      row.subjectName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(_ComponentsCell(components: row.components)),
                  DataCell(
                    Text(
                      '${_number(row.obtainedMarks)} / ${_number(row.totalMarks)}',
                    ),
                  ),
                  DataCell(Text('${row.percentage.toStringAsFixed(1)}%')),
                  DataCell(Text(row.grade)),
                  DataCell(Text(row.isPassed ? 'Pass' : 'Fail')),
                  if (showRemarks)
                    DataCell(
                      Text(
                        row.remarks.trim().isEmpty
                            ? 'Not available'
                            : row.remarks,
                      ),
                    ),
                ],
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _ComponentsCell extends StatelessWidget {
  const _ComponentsCell({required this.components});

  final List<GroupedSubjectComponent> components;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: components
            .map((component) {
              return Container(
                constraints: const BoxConstraints(minWidth: 82),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      component.label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      component.isAbsent
                          ? 'Absent'
                          : '${_number(component.obtainedMarks)} / ${_number(component.totalMarks)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
