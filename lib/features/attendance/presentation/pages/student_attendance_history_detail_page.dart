import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/manual_date_picker.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../domain/entities/attendance_entity.dart';

class StudentAttendanceHistoryDetailPage extends StatefulWidget {
  const StudentAttendanceHistoryDetailPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.classId,
    required this.sectionId,
    required this.records,
  });

  final String studentId;
  final String studentName;
  final String admissionNo;
  final String classId;
  final String sectionId;
  final List<AttendanceEntity> records;

  @override
  State<StudentAttendanceHistoryDetailPage> createState() =>
      _StudentAttendanceHistoryDetailPageState();
}

class _StudentAttendanceHistoryDetailPageState
    extends State<StudentAttendanceHistoryDetailPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    final latest = widget.records.isEmpty
        ? DateTime.now()
        : widget.records
            .map((record) => record.attendanceDate)
            .reduce((first, second) => first.isAfter(second) ? first : second);
    _focusedDay = latest;
  }

  List<AttendanceEntity> get _filteredRecords {
    final records = widget.records.where((record) {
      final day = _dayOnly(record.attendanceDate);
      if (_dateRange != null) {
        return !day.isBefore(_dayOnly(_dateRange!.start)) &&
            !day.isAfter(_dayOnly(_dateRange!.end));
      }
      return day.year == _focusedDay.year && day.month == _focusedDay.month;
    }).toList();
    records.sort((first, second) => second.attendanceDate.compareTo(first.attendanceDate));
    return records;
  }

  Future<void> _selectDateRange() async {
    final result = await showManualDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (result != null) setState(() => _dateRange = result);
  }

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;
    final statistics = _StudentStatistics.fromRecords(records);
    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Student Attendance History')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StudentHeader(widget: widget),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range_outlined),
                        label: Text(
                          _dateRange == null
                              ? 'Choose date range'
                              : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                        ),
                      ),
                      if (_dateRange != null)
                        TextButton.icon(
                          onPressed: () => setState(() => _dateRange = null),
                          icon: const Icon(Icons.clear),
                          label: const Text('Use monthly view'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 5
                          : constraints.maxWidth >= 560
                              ? 3
                              : 2;
                      return GridView.count(
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.9,
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
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Attendance calendar', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TableCalendar<AttendanceEntity>(
                        firstDay: DateTime(2020),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        eventLoader: (day) => widget.records
                            .where((record) => isSameDay(record.attendanceDate, day))
                            .toList(),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            _dateRange = DateTimeRange(start: selectedDay, end: selectedDay);
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                            _dateRange = null;
                          });
                        },
                        calendarStyle: const CalendarStyle(
                          markerDecoration: BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Date-wise attendance', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (records.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No attendance found for this period.')),
                      ),
                    )
                  else
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(record.status).withValues(alpha: 0.14),
                              child: Icon(Icons.calendar_today_outlined, color: _statusColor(record.status)),
                            ),
                            title: Text(_formatDate(record.attendanceDate)),
                            subtitle: record.remarks.isEmpty ? null : Text(record.remarks),
                            trailing: _StatusChip(status: record.status),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({required this.widget});
  final StudentAttendanceHistoryDetailPage widget;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(widget.studentName.isEmpty ? '?' : widget.studentName[0].toUpperCase()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.studentName, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Admission No: ${widget.admissionNo}'),
                  Text('Class: ${widget.classId} • Section: ${widget.sectionId}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final AttendanceStatus status;
  @override
  Widget build(BuildContext context) => Chip(
        label: Text(status.name.toUpperCase()),
        backgroundColor: _statusColor(status).withValues(alpha: 0.14),
        side: BorderSide.none,
        labelStyle: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold),
      );
}

class _StudentStatistics {
  const _StudentStatistics({required this.present, required this.absent, required this.late, required this.leave});
  final int present;
  final int absent;
  final int late;
  final int leave;
  int get total => present + absent + late + leave;
  double get percentage => total == 0 ? 0 : ((present + late) / total) * 100;
  factory _StudentStatistics.fromRecords(List<AttendanceEntity> records) {
    int count(AttendanceStatus status) => records.where((record) => record.status == status).length;
    return _StudentStatistics(present: count(AttendanceStatus.present), absent: count(AttendanceStatus.absent), late: count(AttendanceStatus.late), leave: count(AttendanceStatus.leave));
  }
}

DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

Color _statusColor(AttendanceStatus status) => switch (status) {
      AttendanceStatus.present => Colors.green,
      AttendanceStatus.absent => Colors.red,
      AttendanceStatus.late => Colors.blue,
      AttendanceStatus.leave => Colors.orange,
    };

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
