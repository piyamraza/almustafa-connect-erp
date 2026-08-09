import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../../core/widgets/manual_date_picker.dart';
import '../../domain/entities/teacher_attendance_entity.dart';
import '../../domain/entities/teacher_entity.dart';
import '../../domain/repositories/teacher_attendance_repository.dart';
import '../../domain/repositories/teacher_repository.dart';

class TeacherAttendanceHistoryPage extends StatefulWidget {
  const TeacherAttendanceHistoryPage({super.key});

  @override
  State<TeacherAttendanceHistoryPage> createState() =>
      _TeacherAttendanceHistoryPageState();
}

class _TeacherAttendanceHistoryPageState
    extends State<TeacherAttendanceHistoryPage> {
  late final Future<List<TeacherEntity>> _teachers;
  TeacherEntity? _teacher;
  DateTime _focusedDay = DateTime.now();
  DateTimeRange? _range;
  Future<List<TeacherAttendanceEntity>>? _history;

  @override
  void initState() {
    super.initState();
    _teachers = sl<TeacherRepository>().getTeachers();
  }

  void _load() {
    final teacher = _teacher;
    if (teacher == null) return;
    final from = _range?.start ??
        DateTime(_focusedDay.year, _focusedDay.month);
    final to = _range?.end ??
        DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    setState(() {
      _history = sl<TeacherAttendanceRepository>()
          .getByTeacher(teacher.id, from, to)
          .timeout(const Duration(seconds: 30))
          .then((records) {
            records.sort(
              (first, second) =>
                  second.attendanceDate.compareTo(first.attendanceDate),
            );
            return records;
          });
    });
  }

  Future<void> _pickRange() async {
    final range = await showManualDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (range == null || !mounted) return;
    setState(() => _range = range);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Attendance History'),
        actions: [
          const DashboardNavigationButton(),
          IconButton(
            tooltip: 'Refresh History',
            onPressed: _teacher == null ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FutureBuilder<List<TeacherEntity>>(
              future: _teachers,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: const Text('Unable to load teachers'),
                    subtitle: Text('${snapshot.error}'),
                  );
                }
                return DropdownButtonFormField<TeacherEntity>(
                  initialValue: _teacher,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select teacher',
                    border: OutlineInputBorder(),
                  ),
                  items: (snapshot.data ?? const <TeacherEntity>[])
                      .map(
                        (teacher) => DropdownMenuItem(
                          value: teacher,
                          child: Text(
                            '${teacher.fullName} (${teacher.employeeId})',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _teacher = value);
                    _load();
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text(
                  _range == null
                      ? 'Current month'
                      : '${_date(_range!.start)} - ${_date(_range!.end)}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _historyContent()),
          ],
        ),
      ),
    );
  }

  Widget _historyContent() {
    final history = _history;
    if (history == null) {
      return const Center(
        child: Text('Select a teacher to view attendance history.'),
      );
    }
    return FutureBuilder<List<TeacherAttendanceEntity>>(
      future: history,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load teacher attendance history',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final records = snapshot.data ?? const <TeacherAttendanceEntity>[];
        final present = _count(records, TeacherAttendanceStatus.present);
        final absent = _count(records, TeacherAttendanceStatus.absent);
        final late = _count(records, TeacherAttendanceStatus.late);
        final leave = _count(records, TeacherAttendanceStatus.leave);
        final percentage = records.isEmpty
            ? 0.0
            : ((present + late) / records.length) * 100;

        return SingleChildScrollView(
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) => GridView.count(
                  crossAxisCount: constraints.maxWidth > 700 ? 5 : 2,
                  childAspectRatio: 1.8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _metric('Present', '$present', Colors.green),
                    _metric('Absent', '$absent', Colors.red),
                    _metric('Late', '$late', Colors.blue),
                    _metric('Leave', '$leave', Colors.orange),
                    _metric(
                      'Attendance',
                      '${percentage.toStringAsFixed(1)}%',
                      Colors.teal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TableCalendar<TeacherAttendanceEntity>(
                    firstDay: DateTime(2020),
                    lastDay: DateTime.now(),
                    focusedDay: _focusedDay,
                    eventLoader: (day) => records
                        .where((record) =>
                            isSameDay(record.attendanceDate, day))
                        .toList(),
                    onPageChanged: (day) {
                      setState(() {
                        _focusedDay = day;
                        _range = null;
                      });
                      _load();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: records.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No attendance records for this period.'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return ListTile(
                            title: Text(_date(record.attendanceDate)),
                            subtitle: record.remarks.isEmpty
                                ? null
                                : Text(record.remarks),
                            trailing: Chip(
                              label: Text(record.status.name.toUpperCase()),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _count(
    List<TeacherAttendanceEntity> records,
    TeacherAttendanceStatus status,
  ) => records.where((record) => record.status == status).length;

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  Widget _metric(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
