import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../domain/entities/attendance_entity.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_state.dart';
import 'mark_attendance_page.dart';
import 'student_attendance_page.dart';

class AttendanceCalendarPage extends StatefulWidget {
  const AttendanceCalendarPage({
    super.key,
    required this.classId,
    this.sectionId,
  });

  final String classId;
  final String? sectionId;

  @override
  State<AttendanceCalendarPage> createState() => _AttendanceCalendarPageState();
}

class _AttendanceCalendarPageState extends State<AttendanceCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        if (state is AttendanceLoading) return const Center(child: CircularProgressIndicator());
        if (state is AttendanceError) return Center(child: Text(state.message));
        if (state is! AttendanceLoaded) return const SizedBox();

        final grouped = <DateTime, List<AttendanceEntity>>{};
        for (final record in state.attendance) {
          if (record.classId != widget.classId ||
              (widget.sectionId != null && record.sectionId != widget.sectionId)) {
            continue;
          }
          final day = DateTime(record.attendanceDate.year, record.attendanceDate.month, record.attendanceDate.day);
          grouped.putIfAbsent(day, () => []).add(record);
        }

        final selectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
        final selectedRecords = grouped[selectedDate] ?? const <AttendanceEntity>[];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TableCalendar<AttendanceEntity>(
                  firstDay: DateTime.utc(2020),
                  lastDay: DateTime.utc(2035),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  rowHeight: 42,
                  daysOfWeekHeight: 28,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) => setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  }),
                  eventLoader: (day) => grouped[DateTime(day.year, day.month, day.day)] ?? const [],
                ),
                const SizedBox(height: 24),
                Text('Selected Date', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: selectedRecords.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No attendance found for the selected date.')),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              _buildSummaryRow('Present', _count(selectedRecords, AttendanceStatus.present), Colors.green),
                              const SizedBox(height: 12),
                              _buildSummaryRow('Absent', _count(selectedRecords, AttendanceStatus.absent), Colors.red),
                              const SizedBox(height: 12),
                              _buildSummaryRow('Late', _count(selectedRecords, AttendanceStatus.late), Colors.blue),
                              const SizedBox(height: 12),
                              _buildSummaryRow('Leave', _count(selectedRecords, AttendanceStatus.leave), Colors.orange),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context.read<AttendanceBloc>(),
                                        child: StudentAttendancePage(
                                          classId: widget.classId,
                                          sectionId: widget.sectionId,
                                          selectedDate: selectedDate,
                                        ),
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.people),
                                  label: const Text('View Students'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context.read<AttendanceBloc>(),
                                        child: MarkAttendancePage(
                                          isEditMode: true,
                                          attendanceDate: selectedDate,
                                          classId: widget.classId,
                                          sectionId: widget.sectionId,
                                        ),
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.edit_calendar_outlined),
                                  label: const Text('Edit Attendance'),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _count(List<AttendanceEntity> records, AttendanceStatus status) =>
      records.where((record) => record.status == status).length;

  Widget _buildSummaryRow(String title, int count, Color color) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
        Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}
