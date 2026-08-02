import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/teacher_attendance_entity.dart';
import '../../domain/entities/teacher_entity.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../bloc/teacher_attendance_bloc.dart';
import 'teacher_attendance_history_page.dart';
import 'teacher_attendance_report_page.dart';

class TeacherAttendancePage extends StatelessWidget {
  const TeacherAttendancePage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider<TeacherAttendanceBloc>(
    create: (_) =>
        sl<TeacherAttendanceBloc>()..add(LoadTeacherAttendance(DateTime.now())),
    child: const _TeacherAttendanceView(),
  );
}

class _TeacherAttendanceView extends StatefulWidget {
  const _TeacherAttendanceView();
  @override
  State<_TeacherAttendanceView> createState() => _TeacherAttendanceViewState();
}

class _TeacherAttendanceViewState extends State<_TeacherAttendanceView> {
  late final Future<List<TeacherEntity>> _teachers = sl<TeacherRepository>()
      .getTeachers();
  final Map<String, TeacherAttendanceStatus> _statuses = {};
  DateTime _date = DateTime.now();

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    setState(() => _date = date);
    context.read<TeacherAttendanceBloc>().add(LoadTeacherAttendance(date));
  }

  void _save(List<TeacherEntity> teachers) {
    final existing = context.read<TeacherAttendanceBloc>().state;
    final byTeacher = existing is TeacherAttendanceLoaded
        ? {for (final item in existing.records) item.teacherId: item}
        : <String, TeacherAttendanceEntity>{};
    final now = DateTime.now();
    final records = teachers.map((teacher) {
      final previous = byTeacher[teacher.id];
      return TeacherAttendanceEntity(
        id:
            previous?.id ??
            '${teacher.id}_${_date.year}${_date.month.toString().padLeft(2, '0')}${_date.day.toString().padLeft(2, '0')}',
        teacherId: teacher.id,
        teacherName: teacher.fullName,
        attendanceDate: _date,
        status:
            _statuses[teacher.id] ??
            previous?.status ??
            TeacherAttendanceStatus.present,
        remarks: previous?.remarks ?? '',
        createdAt: previous?.createdAt ?? now,
        updatedAt: now,
      );
    }).toList();
    context.read<TeacherAttendanceBloc>().add(
      SaveTeacherAttendance(records, _date),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${records.length} attendance record(s) saved.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Teacher Attendance'),
      actions: [const DashboardNavigationButton(),
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Attendance History',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TeacherAttendanceHistoryPage(),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.assessment_outlined),
          tooltip: 'Attendance Report',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TeacherAttendanceReportPage(),
            ),
          ),
        ),
      ],
    ),
    floatingActionButton: FutureBuilder<List<TeacherEntity>>(
      future: _teachers,
      builder: (context, snapshot) => snapshot.hasData
          ? FloatingActionButton.extended(
              onPressed: () => _save(snapshot.data!),
              icon: const Icon(Icons.save),
              label: const Text('Save Attendance'),
            )
          : const SizedBox(),
    ),
    body: FutureBuilder<List<TeacherEntity>>(
      future: _teachers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final teachers = snapshot.data!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text('${_date.day}/${_date.month}/${_date.year}'),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<TeacherAttendanceBloc, TeacherAttendanceState>(
                builder: (context, state) {
                  if (state is TeacherAttendanceLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final previous = state is TeacherAttendanceLoaded
                      ? {
                          for (final item in state.records)
                            item.teacherId: item.status,
                        }
                      : <String, TeacherAttendanceStatus>{};
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: teachers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final teacher = teachers[index];
                      final status =
                          _statuses[teacher.id] ??
                          previous[teacher.id] ??
                          TeacherAttendanceStatus.present;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              teacher.firstName.isEmpty
                                  ? '?'
                                  : teacher.firstName[0].toUpperCase(),
                            ),
                          ),
                          title: Text(teacher.fullName),
                          subtitle: Text(
                            '${teacher.employeeId} • ${teacher.designation}',
                          ),
                          trailing: SizedBox(
                            width: 145,
                            child:
                                DropdownButtonFormField<
                                  TeacherAttendanceStatus
                                >(
                                  initialValue: status,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: TeacherAttendanceStatus.values
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value.name.toUpperCase()),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(
                                        () => _statuses[teacher.id] = value,
                                      );
                                    }
                                  },
                                ),
                          ),
                        ),
                      );
                    },
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
