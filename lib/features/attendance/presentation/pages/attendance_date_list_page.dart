import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/attendance_entity.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class AttendanceDateListPage extends StatelessWidget {
  const AttendanceDateListPage({
    super.key,
    required this.classId,
    this.sectionId,
  });

  final String classId;
  final String? sectionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AttendanceBloc>()..add(const LoadAttendanceEvent()),
      child: Scaffold(
        appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Attendance Dates')),
        body: BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            if (state is AttendanceLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AttendanceError) {
              return Center(child: Text(state.message));
            }
            if (state is! AttendanceLoaded) return const SizedBox();

            final groupedAttendance = <DateTime, List<AttendanceEntity>>{};
            for (final attendance in state.attendance) {
              if (attendance.classId != classId ||
                  (sectionId != null && attendance.sectionId != sectionId)) {
                continue;
              }

              final date = DateTime(
                attendance.attendanceDate.year,
                attendance.attendanceDate.month,
                attendance.attendanceDate.day,
              );
              groupedAttendance.putIfAbsent(date, () => []).add(attendance);
            }

            final dates = groupedAttendance.keys.toList()
              ..sort((a, b) => b.compareTo(a));
            if (dates.isEmpty) {
              return const Center(
                child: Text('No attendance history found.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final records = groupedAttendance[date]!;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month),
                            const SizedBox(width: 10),
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildStatusChip(
                              'Present',
                              _count(records, AttendanceStatus.present),
                              Colors.green,
                            ),
                            _buildStatusChip(
                              'Absent',
                              _count(records, AttendanceStatus.absent),
                              Colors.red,
                            ),
                            _buildStatusChip(
                              'Late',
                              _count(records, AttendanceStatus.late),
                              Colors.blue,
                            ),
                            _buildStatusChip(
                              'Leave',
                              _count(records, AttendanceStatus.leave),
                              Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  int _count(List<AttendanceEntity> records, AttendanceStatus status) {
    return records.where((record) => record.status == status).length;
  }

  Widget _buildStatusChip(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$title: $count',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
