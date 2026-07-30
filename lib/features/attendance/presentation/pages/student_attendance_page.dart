import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/attendance_entity.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class StudentAttendancePage extends StatefulWidget {
  final String? classId;
  final String? sectionId;
  final DateTime? selectedDate;

  const StudentAttendancePage({
    super.key,
    this.classId,
    this.sectionId,
    this.selectedDate,
  });

  @override
  State<StudentAttendancePage> createState() =>
      _StudentAttendancePageState();
}

class _StudentAttendancePageState
    extends State<StudentAttendancePage> {
  final TextEditingController _searchController =
      TextEditingController();

  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AttendanceBloc? inheritedBloc;
    try {
      inheritedBloc = BlocProvider.of<AttendanceBloc>(context);
    } catch (_) {
      inheritedBloc = null;
    }

    final page = Builder(
      builder: (context) => Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance'),
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state is AttendanceLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is AttendanceError) {
            return Center(
              child: Text(state.message),
            );
          }

          if (state is! AttendanceLoaded) {
            return const SizedBox();
          }

          final selectedDate = widget.selectedDate == null
              ? null
              : DateTime(
                  widget.selectedDate!.year,
                  widget.selectedDate!.month,
                  widget.selectedDate!.day,
                );

          final records = state.attendance.where((item) {
            final attendanceDate = DateTime(
              item.attendanceDate.year,
              item.attendanceDate.month,
              item.attendanceDate.day,
            );

            final matchesDate = selectedDate == null || attendanceDate == selectedDate;

            final matchesClass =
                widget.classId == null || item.classId == widget.classId;

            final matchesSection =
                widget.sectionId == null ||
                    item.sectionId ==
                        widget.sectionId;

            final matchesSearch =
                item.studentName
                    .toLowerCase()
                    .contains(
                      _search.toLowerCase(),
                    ) ||
                item.admissionNo
                    .toLowerCase()
                    .contains(
                      _search.toLowerCase(),
                    );

            return matchesDate &&
                matchesClass &&
                matchesSection &&
                matchesSearch;
          }).toList();

          records.sort(
            (a, b) => a.studentName.compareTo(
              b.studentName,
            ),
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText:
                        'Search student...',
                    border:
                        OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _search = value;
                    });
                  },
                ),
              ),

              Expanded(
                child: records.isEmpty
                    ? const Center(
                        child: Text(
                          'No attendance found.',
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        itemCount: records.length,
                        itemBuilder:
                            (context, index) {
                          final student =
                              records[index];
                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  student.studentName
                                      .isNotEmpty
                                      ? student.studentName[0]
                                          .toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text(
                                student.studentName,
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admission No: ${student.admissionNo}',
                                  ),
                                 
                                ],
                              ),
                              trailing: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    student.status,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    20,
                                  ),
                                ),
                                child: Text(
                                  _statusText(
                                    student.status,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      ),
    );
    return inheritedBloc == null
        ? BlocProvider<AttendanceBloc>(
            create: (_) => sl<AttendanceBloc>()..add(const LoadAttendanceEvent()),
            child: page,
          )
        : BlocProvider<AttendanceBloc>.value(
            value: inheritedBloc,
            child: page,
          );
  }

  Color _statusColor(
    AttendanceStatus status,
  ) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;

      case AttendanceStatus.absent:
        return Colors.red;

      case AttendanceStatus.late:
        return Colors.blue;

      case AttendanceStatus.leave:
        return Colors.orange;
    }
  }

  String _statusText(
    AttendanceStatus status,
  ) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';

      case AttendanceStatus.absent:
        return 'Absent';

      case AttendanceStatus.late:
        return 'Late';

      case AttendanceStatus.leave:
        return 'Leave';
    }
  }
}
