import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/entities/attendance_report.dart';
import '../bloc/attendance_report_bloc.dart';
import '../bloc/attendance_report_event.dart';
import '../bloc/attendance_report_state.dart';
import '../services/attendance_report_export_service.dart';

class AttendanceReportsPage extends StatelessWidget {
  const AttendanceReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AttendanceReportBloc>(
      create: (_) => sl<AttendanceReportBloc>()
        ..add(GenerateAttendanceReportEvent(_defaultFilter())),
      child: const _AttendanceReportsView(),
    );
  }

  static AttendanceReportFilter _defaultFilter() {
    final now = DateTime.now();
    return AttendanceReportFilter(
      type: AttendanceReportType.monthly,
      fromDate: DateTime(now.year, now.month),
      toDate: DateTime(now.year, now.month + 1, 0),
    );
  }
}

class _AttendanceReportsView extends StatefulWidget {
  const _AttendanceReportsView();

  @override
  State<_AttendanceReportsView> createState() =>
      _AttendanceReportsViewState();
}

class _AttendanceReportsViewState extends State<_AttendanceReportsView> {
  late AttendanceReportFilter _filter = AttendanceReportsPage._defaultFilter();
  final AttendanceReportExportService _exportService =
      AttendanceReportExportService();

  void _generateReport() {
    context
        .read<AttendanceReportBloc>()
        .add(GenerateAttendanceReportEvent(_filter));
  }

  void _updateFilter({
    AttendanceReportType? type,
    DateTime? fromDate,
    DateTime? toDate,
    String? classId,
    String? sectionId,
    String? studentId,
    bool clearClass = false,
    bool clearSection = false,
    bool clearStudent = false,
  }) {
    setState(() {
      _filter = AttendanceReportFilter(
        type: type ?? _filter.type,
        fromDate: fromDate ?? _filter.fromDate,
        toDate: toDate ?? _filter.toDate,
        classId: clearClass ? null : classId ?? _filter.classId,
        sectionId: clearSection ? null : sectionId ?? _filter.sectionId,
        studentId: clearStudent ? null : studentId ?? _filter.studentId,
      );
    });
    _generateReport();
  }

  Future<void> _selectDate({required bool isFromDate}) async {
    final initialDate = isFromDate ? _filter.fromDate : _filter.toDate;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selectedDate == null) return;

    if (isFromDate && selectedDate.isAfter(_filter.toDate)) {
      _updateFilter(fromDate: selectedDate, toDate: selectedDate);
    } else if (!isFromDate && selectedDate.isBefore(_filter.fromDate)) {
      _updateFilter(fromDate: selectedDate, toDate: selectedDate);
    } else {
      _updateFilter(
        fromDate: isFromDate ? selectedDate : null,
        toDate: isFromDate ? null : selectedDate,
      );
    }
  }

  Future<void> _export(String action, AttendanceReport report) async {
    try {
      switch (action) {
        case 'pdf':
          await _exportService.sharePdf(report);
          return;
        case 'excel':
          await _exportService.shareExcel(report);
          return;
        case 'print':
          await _exportService.print(report);
          return;
        default:
          return;
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to export report: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Reports')),
      body: SafeArea(
        child: BlocBuilder<AttendanceReportBloc, AttendanceReportState>(
          builder: (context, state) {
            final report = state is AttendanceReportLoaded ? state.report : null;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FilterPanel(
                        filter: _filter,
                        report: report,
                        onTypeChanged: _changeReportType,
                        onFromDatePressed: () => _selectDate(isFromDate: true),
                        onToDatePressed: () => _selectDate(isFromDate: false),
                        onClassChanged: (value) => _updateFilter(
                          classId: value,
                          clearClass: value == null,
                        ),
                        onSectionChanged: (value) => _updateFilter(
                          sectionId: value,
                          clearSection: value == null,
                        ),
                        onStudentChanged: (value) => _updateFilter(
                          studentId: value,
                          clearStudent: value == null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (state is AttendanceReportLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (state is AttendanceReportError)
                        Center(child: Text(state.message))
                      else if (report != null)
                        _ReportContent(
                          report: report,
                          onExport: (action) => _export(action, report),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _changeReportType(AttendanceReportType type) {
    final now = DateTime.now();
    switch (type) {
      case AttendanceReportType.daily:
        _updateFilter(type: type, fromDate: now, toDate: now);
        return;
      case AttendanceReportType.monthly:
        _updateFilter(
          type: type,
          fromDate: DateTime(now.year, now.month),
          toDate: DateTime(now.year, now.month + 1, 0),
        );
        return;
      case AttendanceReportType.dateRange:
      case AttendanceReportType.classWise:
      case AttendanceReportType.sectionWise:
      case AttendanceReportType.studentWise:
        _updateFilter(type: type);
        return;
    }
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.filter,
    required this.report,
    required this.onTypeChanged,
    required this.onFromDatePressed,
    required this.onToDatePressed,
    required this.onClassChanged,
    required this.onSectionChanged,
    required this.onStudentChanged,
  });

  final AttendanceReportFilter filter;
  final AttendanceReport? report;
  final ValueChanged<AttendanceReportType> onTypeChanged;
  final VoidCallback onFromDatePressed;
  final VoidCallback onToDatePressed;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onStudentChanged;

  @override
  Widget build(BuildContext context) {
    final List<AttendanceEntity> records =
        report?.records ?? const <AttendanceEntity>[];
    final classes = records.map((record) => record.classId).toSet().toList()
      ..sort();
    final sections = records.map((record) => record.sectionId).toSet().toList()
      ..sort();
    final students = <String, String>{
      for (final record in records) record.studentId: record.studentName,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<AttendanceReportType>(
                value: filter.type,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Report type',
                  border: OutlineInputBorder(),
                ),
                items: AttendanceReportType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_typeLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onTypeChanged(value);
                },
              ),
            ),
            _DateFilterButton(
              label: 'From: ${_formatDate(filter.fromDate)}',
              onPressed: onFromDatePressed,
            ),
            _DateFilterButton(
              label: 'To: ${_formatDate(filter.toDate)}',
              onPressed: onToDatePressed,
            ),
            _StringFilter(
              label: 'Class',
              value: filter.classId,
              values: classes,
              displayText: (value) => value,
              onChanged: onClassChanged,
            ),
            _StringFilter(
              label: 'Section',
              value: filter.sectionId,
              values: sections,
              displayText: (value) => value,
              onChanged: onSectionChanged,
            ),
            _StringFilter(
              label: 'Student',
              value: filter.studentId,
              values: students.keys.toList(),
              displayText: (value) => students[value] ?? value,
              onChanged: onStudentChanged,
            ),
          ],
        ),
      ),
    );
  }

  static String _typeLabel(AttendanceReportType type) {
    return switch (type) {
      AttendanceReportType.daily => 'Daily attendance',
      AttendanceReportType.monthly => 'Monthly attendance',
      AttendanceReportType.dateRange => 'Date range attendance',
      AttendanceReportType.classWise => 'Class-wise attendance',
      AttendanceReportType.sectionWise => 'Section-wise attendance',
      AttendanceReportType.studentWise => 'Student-wise attendance',
    };
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(label),
      ),
    );
  }
}

class _StringFilter extends StatelessWidget {
  const _StringFilter({
    required this.label,
    required this.value,
    required this.values,
    required this.displayText,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> values;
  final String Function(String) displayText;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = values.contains(value) ? value : null;
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('All')),
          ...values.map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(displayText(item), overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.report, required this.onExport});

  final AttendanceReport report;
  final ValueChanged<String> onExport;

  @override
  Widget build(BuildContext context) {
    final statistics = report.statistics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Report overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            PopupMenuButton<String>(
              onSelected: onExport,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'pdf', child: Text('Export / Share PDF')),
                PopupMenuItem(
                  value: 'excel',
                  child: Text('Export / Share Excel'),
                ),
                PopupMenuItem(value: 'print', child: Text('Print')),
              ],
              child: const Chip(
                avatar: Icon(Icons.ios_share, size: 18),
                label: Text('Export'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth >= 1050
                ? 6
                : constraints.maxWidth >= 650
                    ? 3
                    : 2;
            return GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _MetricCard('Present', '${statistics.present}', Colors.green),
                _MetricCard('Absent', '${statistics.absent}', Colors.red),
                _MetricCard('Late', '${statistics.late}', Colors.blue),
                _MetricCard('Leave', '${statistics.leave}', Colors.orange),
                _MetricCard(
                  'Attendance',
                  '${statistics.percentage.toStringAsFixed(1)}%',
                  Colors.teal,
                ),
                _MetricCard(
                  'Working days',
                  '${statistics.workingDays}',
                  Colors.indigo,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _Charts(report: report),
        const SizedBox(height: 20),
        Text(_tableTitle(report.filter.type), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _ReportSummaryTable(report: report),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Charts extends StatelessWidget {
  const _Charts({required this.report});

  final AttendanceReport report;

  @override
  Widget build(BuildContext context) {
    final statistics = report.statistics;
    final total = statistics.total;
    final distribution = <_DistributionItem>[
      _DistributionItem('Present', statistics.present, Colors.green),
      _DistributionItem('Absent', statistics.absent, Colors.red),
      _DistributionItem('Late', statistics.late, Colors.blue),
      _DistributionItem('Leave', statistics.leave, Colors.orange),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 750;
        final distributionCard = _ChartCard(
          title: 'Attendance distribution',
          child: Column(
            children: distribution
                .map(
                  (item) => _DistributionRow(
                    item: item,
                    total: total,
                  ),
                )
                .toList(),
          ),
        );
        final trendCard = _ChartCard(
          title: 'Monthly trend',
          child: report.monthlyTrend.isEmpty
              ? const Text('No attendance records for the selected period.')
              : Column(
                  children: report.monthlyTrend.entries
                      .map(
                        (entry) => _TrendRow(
                          label: entry.key,
                          percentage: entry.value,
                        ),
                      )
                      .toList(),
                ),
        );

        if (!isWide) {
          return Column(
            children: [distributionCard, const SizedBox(height: 16), trendCard],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: distributionCard),
            const SizedBox(width: 16),
            Expanded(child: trendCard),
          ],
        );
      },
    );
  }
}

class _DistributionItem {
  const _DistributionItem(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(title), const SizedBox(height: 16), child],
        ),
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({required this.item, required this.total});
  final _DistributionItem item;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 62, child: Text(item.label)),
          Expanded(
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : item.value / total,
              color: item.color,
              minHeight: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text('${item.value}'),
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.label, required this.percentage});
  final String label;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 76, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text('${percentage.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}

class _ReportSummaryTable extends StatelessWidget {
  const _ReportSummaryTable({required this.report});
  final AttendanceReport report;

  @override
  Widget build(BuildContext context) {
    final type = report.filter.type;
    final isStudent = type == AttendanceReportType.studentWise ||
        type == AttendanceReportType.monthly ||
        type == AttendanceReportType.dateRange;
    final groups = switch (type) {
      AttendanceReportType.classWise => report.classStatistics,
      AttendanceReportType.sectionWise => report.sectionStatistics,
      AttendanceReportType.daily => report.dailyStatistics,
      _ => report.studentStatistics,
    };
    final rows = groups.entries.map((entry) {
      if (!isStudent) {
        final statistics = entry.value;
        return DataRow(
          cells: [
            DataCell(Text(entry.key)),
            DataCell(Text('${statistics.present}')),
            DataCell(Text('${statistics.absent}')),
            DataCell(Text('${statistics.late}')),
            DataCell(Text('${statistics.leave}')),
            DataCell(Text('${statistics.percentage.toStringAsFixed(1)}%')),
          ],
        );
      }
      final student = report.records.firstWhere(
        (record) => record.studentId == entry.key,
      );
      final statistics = entry.value;
      return DataRow(
        cells: [
          DataCell(Text(student.admissionNo)),
          DataCell(Text(student.studentName)),
          DataCell(Text(student.classId)),
          DataCell(Text('${statistics.present}/${statistics.total}')),
          DataCell(Text('${statistics.percentage.toStringAsFixed(1)}%')),
        ],
      );
    }).toList();

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: isStudent ? const [
            DataColumn(label: Text('Admission #')),
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Class')),
            DataColumn(label: Text('Present / Total')),
            DataColumn(label: Text('Attendance %')),
          ] : const [
            DataColumn(label: Text('Group')),
            DataColumn(label: Text('Present')),
            DataColumn(label: Text('Absent')),
            DataColumn(label: Text('Late')),
            DataColumn(label: Text('Leave')),
            DataColumn(label: Text('Attendance %')),
          ],
          rows: rows,
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _tableTitle(AttendanceReportType type) {
  return switch (type) {
    AttendanceReportType.daily => 'Daily attendance summary',
    AttendanceReportType.monthly => 'Student attendance summary',
    AttendanceReportType.dateRange => 'Student attendance summary',
    AttendanceReportType.classWise => 'Class-wise attendance summary',
    AttendanceReportType.sectionWise => 'Section-wise attendance summary',
    AttendanceReportType.studentWise => 'Student-wise attendance summary',
  };
}
