import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_reference_resolver.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../domain/entities/attendance_entity.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import 'student_attendance_history_detail_page.dart';

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({
    super.key,
    this.classId,
    this.sectionId,
    this.selectedDate,
  });

  final String? classId;
  final String? sectionId;
  final DateTime? selectedDate;

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  Map<String, StudentEntity> _studentDetails = const {};
  AcademicReferenceResolver _academicResolver =
      const AcademicReferenceResolver(classes: [], sections: []);

  @override
  void initState() {
    super.initState();
    _loadStudentDetails();
  }

  Future<void> _loadStudentDetails() async {
    try {
      final values = await Future.wait<Object>([
        sl<StudentRepository>().getStudents(),
        sl<AcademicStructureRepository>().getClasses(),
        sl<AcademicStructureRepository>().getSections(),
      ]);
      final students = values[0] as List<StudentEntity>;
      if (!mounted) return;
      setState(() {
        _studentDetails = {for (final student in students) student.id: student};
        _academicResolver = AcademicReferenceResolver(
          classes: values[1] as List<AcademicClassEntity>,
          sections: values[2] as List<SectionEntity>,
        );
      });
    } catch (_) {
      // Attendance remains available if profile details cannot be loaded.
    }
  }

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

    final content = Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Student Attendance')),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state is AttendanceLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AttendanceError) {
            return Center(child: Text(state.message));
          }
          if (state is! AttendanceLoaded) {
            return const SizedBox();
          }

          final students = _buildStudentSummaries(state.attendance);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _search = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by name, father name or roll number...',
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: students.isEmpty
                    ? const Center(child: Text('No students found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: students.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  student.name.isEmpty
                                      ? '?'
                                      : student.name[0].toUpperCase(),
                                ),
                              ),
                              title: Text(student.name),
                              subtitle: Text(
                                'Father: ${student.fatherName.isEmpty ? '-' : student.fatherName}\n'
                                'Class: ${_academicResolver.className(student.classId)}-'
                                '${_academicResolver.sectionName(student.sectionId)}\n'
                                'Roll No: ${student.rollNumber.isEmpty ? '-' : student.rollNumber}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StudentAttendanceHistoryDetailPage(
                                        studentId: student.studentId,
                                        studentName: student.name,
                                        admissionNo: student.admissionNo,
                                        classId: _academicResolver.className(
                                          student.classId,
                                        ),
                                        sectionId: _academicResolver.sectionName(
                                          student.sectionId,
                                        ),
                                        records: student.records,
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
    );

    return inheritedBloc == null
        ? BlocProvider<AttendanceBloc>(
            create: (_) =>
                sl<AttendanceBloc>()..add(const LoadAttendanceEvent()),
            child: content,
          )
        : BlocProvider<AttendanceBloc>.value(
            value: inheritedBloc,
            child: content,
          );
  }

  List<_StudentAttendanceSummary> _buildStudentSummaries(
    List<AttendanceEntity> records,
  ) {
    final selectedDay = widget.selectedDate == null
        ? null
        : DateTime(
            widget.selectedDate!.year,
            widget.selectedDate!.month,
            widget.selectedDate!.day,
          );
    final grouped = <String, List<AttendanceEntity>>{};
    for (final record in records) {
      final recordDay = DateTime(
        record.attendanceDate.year,
        record.attendanceDate.month,
        record.attendanceDate.day,
      );
      final matchesSelection =
          (selectedDay == null || recordDay == selectedDay) &&
          (widget.classId == null ||
              _academicResolver.sameClass(record.classId, widget.classId!)) &&
          (widget.sectionId == null ||
              _academicResolver.sameSection(
                record.sectionId,
                widget.sectionId!,
              ));
      if (matchesSelection) {
        grouped.putIfAbsent(record.studentId, () => []).add(record);
      }
    }
    final summaries = grouped.entries
        .map((entry) {
          final first = entry.value.first;
          final details = _studentDetails[entry.key];
          return _StudentAttendanceSummary(
            studentId: entry.key,
            name: first.studentName,
            admissionNo: first.admissionNo,
            classId: first.classId,
            sectionId: first.sectionId,
            fatherName: details?.fatherName ?? '',
            rollNumber: details?.rollNumber ?? '',
            records: entry.value,
          );
        })
        .where((student) {
          if (_search.isEmpty) return true;
          return student.name.toLowerCase().contains(_search) ||
              student.fatherName.toLowerCase().contains(_search) ||
              student.rollNumber.toLowerCase().contains(_search);
        })
        .toList();
    summaries.sort((first, second) => first.name.compareTo(second.name));
    return summaries;
  }
}

class _StudentAttendanceSummary {
  const _StudentAttendanceSummary({
    required this.studentId,
    required this.name,
    required this.admissionNo,
    required this.classId,
    required this.sectionId,
    required this.fatherName,
    required this.rollNumber,
    required this.records,
  });

  final String studentId;
  final String name;
  final String admissionNo;
  final String classId;
  final String sectionId;
  final String fatherName;
  final String rollNumber;
  final List<AttendanceEntity> records;
}
