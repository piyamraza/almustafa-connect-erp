import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';

import '../../../students/domain/entities/student_entity.dart';
import '../../../students/presentation/bloc/student_bloc.dart';
import '../../../students/presentation/bloc/student_event.dart';
import '../../../students/presentation/bloc/student_state.dart';

import '../../domain/entities/attendance_entity.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
class MarkAttendancePage extends StatefulWidget {
  const MarkAttendancePage({super.key});

  @override
  State<MarkAttendancePage> createState() =>
      _MarkAttendancePageState();
}

class _MarkAttendancePageState
    extends State<MarkAttendancePage> {
  //------------------------------------------------------------
  // Controllers
  //------------------------------------------------------------

  final TextEditingController _searchController =
      TextEditingController();

  //------------------------------------------------------------
  // Filters
  //------------------------------------------------------------

  DateTime _selectedDate = DateTime.now();

  String? _selectedClass;

  String? _selectedSection;

  //------------------------------------------------------------
  // Attendance Data
  //------------------------------------------------------------

  final Map<String, AttendanceStatus>
      _attendanceStatus = {};

  final Map<String, TextEditingController>
      _remarksControllers = {};

  //------------------------------------------------------------
  // Static Lists
  //------------------------------------------------------------

  final List<String> _classes = const [
    'Nursery',
    'Prep',
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
  ];

  final List<String> _sections = const [
    'A',
    'B',
    'C',
    'D',
  ];

  //------------------------------------------------------------
  // Lifecycle
  //------------------------------------------------------------

  @override
  void initState() {
    super.initState();

_searchController.addListener(() {
  if (mounted) {
    setState(() {});
  }
});

WidgetsBinding.instance.addPostFrameCallback((_) {
  context.read<AttendanceBloc>().add(
    LoadAttendanceByDateEvent(_selectedDate),
  );
});
  }

  @override
  void dispose() {
    _searchController.dispose();

    for (final controller
        in _remarksControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }
  //------------------------------------------------------------
  // Helper Methods
  //------------------------------------------------------------

  Color _statusColor(
    AttendanceStatus status,
  ) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;

      case AttendanceStatus.absent:
        return Colors.red;

      case AttendanceStatus.leave:
        return Colors.orange;

      case AttendanceStatus.late:
        return Colors.blue;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
  _selectedDate = picked;
});

context.read<AttendanceBloc>().add(
  LoadAttendanceByDateEvent(_selectedDate),
);
  }

  List<StudentEntity> _filteredStudents(
    List<StudentEntity> students,
  ) {
    final keyword =
        _searchController.text
            .trim()
            .toLowerCase();

    return students.where((student) {
      final classMatch =
          _selectedClass == null ||
              student.classId == _selectedClass;

      final sectionMatch =
          _selectedSection == null ||
              student.sectionId ==
                  _selectedSection;

      final searchMatch =
          keyword.isEmpty ||
              student.fullName
                  .toLowerCase()
                  .contains(keyword) ||
              student.admissionNo
                  .toLowerCase()
                  .contains(keyword) ||
              student.firstName
                  .toLowerCase()
                  .contains(keyword) ||
              student.lastName
                  .toLowerCase()
                  .contains(keyword);

      return classMatch &&
          sectionMatch &&
          searchMatch;
    }).toList();
  }

  //------------------------------------------------------------
  // Build
  //------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
final attendanceBloc = sl<AttendanceBloc>();
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
  value: attendanceBloc,
),
        BlocProvider(
          create: (_) => sl<StudentBloc>()
            ..add(
              const LoadStudentsEvent(),
            ),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Mark Attendance',
          ),
          centerTitle: false,
        ),

        floatingActionButton:
            FloatingActionButton.extended(
          onPressed: _saveAttendance,
          icon: const Icon(Icons.save),
          label: const Text(
            'Save Attendance',
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              //------------------------------------------
              // Filters
              //------------------------------------------

              Row(
                children: [
                  Expanded(
                    child:
                        DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration:
                          const InputDecoration(
                        labelText: 'Class',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: _classes
                          .map(
                            (item) =>
                                DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClass =
                              value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child:
                        DropdownButtonFormField<String>(
                      value: _selectedSection,
                      decoration:
                          const InputDecoration(
                        labelText: 'Section',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: _sections
                          .map(
                            (item) =>
                                DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSection =
                              value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: IgnorePointer(
                        child: TextFormField(
                          decoration:
                              InputDecoration(
                            labelText:
                                'Attendance Date',
                            border:
                                const OutlineInputBorder(),
                            suffixIcon:
                                const Icon(
                              Icons.calendar_month,
                            ),
                            hintText:
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              //------------------------------------------
              // Search
              //------------------------------------------

              TextField(
                controller:
                    _searchController,
                decoration:
                    const InputDecoration(
                  hintText:
                      'Search by student name or admission no',
                  prefixIcon:
                      Icon(Icons.search),
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              //------------------------------------------
              // Student List
              //------------------------------------------

Expanded(
  child: BlocListener<
      AttendanceBloc,
      AttendanceState>(
    listener: (context, attendanceState) {
      if (attendanceState is AttendanceLoaded) {
        for (final attendance
            in attendanceState.attendance) {
          _attendanceStatus[
              attendance.studentId] = attendance.status;

          _remarksControllers.putIfAbsent(
            attendance.studentId,
            () => TextEditingController(),
          );

          _remarksControllers[
                  attendance.studentId]!
              .text = attendance.remarks;
        }

        if (mounted) {
          setState(() {});
        }
      }
    },
    child: BlocBuilder<
        StudentBloc,
        StudentState>(
                  builder:
                      (context, state) {
                    if (state
                        is StudentLoading) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    if (state
                        is StudentError) {
                      return Center(
                        child: Text(
                          state.message,
                        ),
                      );
                    }

                    if (state
                        is! StudentLoaded) {
                      return const SizedBox();
                    }

                    final students =
                        _filteredStudents(
                      state.students,
                    );

                    if (students
                        .isEmpty) {
                      return const Center(
                        child: Text(
                          'No students found.',
                        ),
                      );
                    }

                    return Card(
                      clipBehavior:
                          Clip.antiAlias,
                      child:
                          ListView.builder(
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        itemCount:
                            students.length,
                        itemBuilder:
                            (context,
                                index) {
                          final student =
                              students[index];

                          _attendanceStatus
                              .putIfAbsent(
                            student.id,
                            () =>
                                AttendanceStatus.present,
                          );

                          _remarksControllers
                              .putIfAbsent(
                            student.id,
                            () =>
                                TextEditingController(),
                          );

                          final status =
                              _attendanceStatus[
                                  student.id]!;

                          final remarksController =
                              _remarksControllers[
                                  student.id]!;
                          return Card(
                            margin:
                                const EdgeInsets.only(
                              left: 12,
                              right: 12,
                              top: 8,
                              bottom: 8,
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(
                                16,
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  //----------------------------------
                                  // Avatar
                                  //----------------------------------

                                  CircleAvatar(
                                    radius: 24,
                                    child: Text(
                                      student.fullName
                                              .isNotEmpty
                                          ? student
                                              .fullName[0]
                                              .toUpperCase()
                                          : '?',
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 16,
                                  ),

                                  //----------------------------------
                                  // Student Information
                                  //----------------------------------

                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          student
                                              .fullName,
                                          style:
                                              Theme.of(
                                            context,
                                          )
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                        ),

                                        const SizedBox(
                                          height: 6,
                                        ),

                                        Text(
                                          'Admission No: ${student.admissionNo}',
                                        ),

                                        const SizedBox(
                                          height: 4,
                                        ),

                                        Text(
                                          'Father: ${student.fatherName}',
                                        ),

                                        const SizedBox(
                                          height: 4,
                                        ),

                                        Text(
                                          'Mobile: ${student.guardianPhone}',
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 20,
                                  ),

                                  //----------------------------------
                                  // Attendance Status
                                  //----------------------------------

                                  SizedBox(
                                    width: 180,
                                    child:
                                        DropdownButtonFormField<
                                            AttendanceStatus>(
                                      value:
                                          status,
                                      decoration:
                                          const InputDecoration(
                                        labelText:
                                            'Status',
                                        border:
                                            OutlineInputBorder(),
                                      ),
                                      items:
                                          AttendanceStatus
                                              .values
                                              .map(
                                                (
                                                  attendanceStatus,
                                                ) =>
                                                    DropdownMenuItem(
                                                  value:
                                                      attendanceStatus,
                                                  child:
                                                      Text(
                                                    attendanceStatus
                                                        .name
                                                        .toUpperCase(),
                                                    style:
                                                        TextStyle(
                                                      color:
                                                          _statusColor(
                                                        attendanceStatus,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          (
                                        value,
                                      ) {
                                        if (value ==
                                            null) {
                                          return;
                                        }

                                        setState(
                                          () {
                                            _attendanceStatus[
                                                    student.id] =
                                                value;
                                          },
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 16,
                                  ),

                                  //----------------------------------
                                  // Remarks
                                  //----------------------------------

                                  Expanded(
                                    flex: 2,
                                    child:
                                        TextFormField(
                                      controller:
                                          remarksController,
                                      minLines: 1,
                                      maxLines: 2,
                                      decoration:
                                          const InputDecoration(
                                        labelText:
                                            'Remarks',
                                        border:
                                            OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
               ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //------------------------------------------------------------
  // Save Attendance
  //------------------------------------------------------------

  Future<void> _saveAttendance() async {
debugPrint('========== SAVE BUTTON PRESSED ==========');
    final attendanceBloc = sl<AttendanceBloc>();

    final studentState =
        context.read<StudentBloc>().state;

    if (studentState is! StudentLoaded) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Students are not loaded.',
          ),
        ),
      );

      return;
    }

    final students = _filteredStudents(
      studentState.students,
    );

    if (students.isEmpty) {
          if (!mounted) return;

    context.read<AttendanceBloc>().add(
      LoadAttendanceByDateEvent(_selectedDate),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${students.length} attendance record(s) saved successfully.',
        ),
      ),
    );

      return;
    }

    final now = DateTime.now();

    for (final student in students) {
debugPrint(
  'Saving ${student.fullName} | ${_attendanceStatus[student.id]}',
);
      attendanceBloc.add(
        AddAttendanceEvent(
          AttendanceEntity(
id:
    '${student.id}_${_selectedDate.year}'
    '${_selectedDate.month.toString().padLeft(2, '0')}'
    '${_selectedDate.day.toString().padLeft(2, '0')}',            studentId: student.id,
            admissionNo: student.admissionNo,
            studentName: student.fullName,
            classId: student.classId,
            sectionId: student.sectionId,
            attendanceDate: _selectedDate,
            status:
                _attendanceStatus[student.id] ??
                    AttendanceStatus.present,
            remarks:
                _remarksControllers[student.id]
                        ?.text
                        .trim() ??
                    '',
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${students.length} attendance record(s) saved successfully.',
        ),
      ),
    );
  }
}
