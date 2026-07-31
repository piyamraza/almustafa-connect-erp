import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/presentation/bloc/student_bloc.dart';
import '../../../students/presentation/bloc/student_event.dart';
import '../../../students/presentation/bloc/student_state.dart';
import '../../domain/entities/attendance_entity.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../widgets/attendance_academic_structure.dart';

class MarkAttendancePage extends StatefulWidget {
  const MarkAttendancePage({
    super.key,
    this.isEditMode = false,
    this.attendanceDate,
    this.classId,
    this.sectionId,
  });

  final bool isEditMode;
  final DateTime? attendanceDate;
  final String? classId;
  final String? sectionId;

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  final AcademicStructureRepository _academicStructureRepository =
      sl<AcademicStructureRepository>();
  final _searchController = TextEditingController();
  final Map<String, AttendanceStatus> _attendanceStatus = {};
  final Map<String, TextEditingController> _remarksControllers = {};
  final Map<String, AttendanceEntity> _existingAttendanceByStudent = {};

  DateTime _selectedDate = DateTime.now();
  String? _selectedClass;
  String? _selectedSection;
  bool _hasRequestedInheritedAttendance = false;
  bool _hasRequestedInheritedStudents = false;
  late Future<AttendanceAcademicStructure> _academicStructureFuture;

  bool get _isChoosingClass => _selectedClass == null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.attendanceDate ?? DateTime.now();
    _selectedClass = widget.classId;
    _selectedSection = widget.sectionId;
    _academicStructureFuture = AttendanceAcademicStructure.load(
      _academicStructureRepository,
    );
    _searchController.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inheritedAttendanceBloc = _findAttendanceBloc();
    if (inheritedAttendanceBloc != null && !_hasRequestedInheritedAttendance) {
      _hasRequestedInheritedAttendance = true;
      _loadAttendanceForDate(inheritedAttendanceBloc, clearDrafts: false);
    }

    final inheritedStudentBloc = _findStudentBloc();
    if (inheritedStudentBloc != null && !_hasRequestedInheritedStudents) {
      _hasRequestedInheritedStudents = true;
      if (inheritedStudentBloc.state is StudentInitial) {
        inheritedStudentBloc.add(const LoadStudentsEvent());
      }
    }
  }

  AttendanceBloc? _findAttendanceBloc() {
    try {
      return BlocProvider.of<AttendanceBloc>(context);
    } catch (_) {
      return null;
    }
  }

  StudentBloc? _findStudentBloc() {
    try {
      return BlocProvider.of<StudentBloc>(context);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    for (final controller in _remarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  void _loadAttendanceForDate(
    AttendanceBloc bloc, {
    required bool clearDrafts,
  }) {
    if (clearDrafts) {
      _attendanceStatus.clear();
      _existingAttendanceByStudent.clear();
      for (final controller in _remarksControllers.values) {
        controller.clear();
      }
    }
    bloc.add(LoadAttendanceByDateEvent(_selectedDate));
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked == null || !context.mounted) {
      return;
    }
    setState(() => _selectedDate = picked);
    _loadAttendanceForDate(context.read<AttendanceBloc>(), clearDrafts: true);
  }

  Future<void> _selectClass(
    BuildContext context,
    String className,
    List<String> sections,
  ) async {
    String? section;
    if (sections.length > 1) {
      section = await _showSectionPicker(context, className, sections);
      if (section == null || !mounted) return;
    } else if (sections.length == 1) {
      section = sections.single;
    }
    _searchController.clear();
    setState(() {
      _selectedClass = className;
      _selectedSection = section;
    });
  }

  Future<String?> _showSectionPicker(
    BuildContext context,
    String className,
    List<String> sections,
  ) => showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Select $className section'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: sections
            .map(
              (section) => ListTile(
                leading: const Icon(Icons.class_outlined),
                title: Text('Section $section'),
                onTap: () => Navigator.pop(dialogContext, section),
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );

  List<StudentEntity> _filteredStudents(List<StudentEntity> students) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = students.where((student) {
      return student.classId == _selectedClass &&
          (_selectedSection == null || student.sectionId == _selectedSection) &&
          (query.isEmpty ||
              student.fullName.toLowerCase().contains(query) ||
              student.admissionNo.toLowerCase().contains(query) ||
              student.rollNumber.toLowerCase().contains(query));
    }).toList();
    filtered.sort(_compareByRollNumber);
    return filtered;
  }

  int _compareByRollNumber(StudentEntity first, StudentEntity second) {
    final firstNumber = int.tryParse(first.rollNumber.trim());
    final secondNumber = int.tryParse(second.rollNumber.trim());
    if (firstNumber != null && secondNumber != null) {
      return firstNumber.compareTo(secondNumber);
    }
    if (firstNumber != null) return -1;
    if (secondNumber != null) return 1;
    return first.rollNumber.compareTo(second.rollNumber);
  }

  void _cacheAttendance(List<AttendanceEntity> records) {
    final selectedDay = _dayOnly(_selectedDate);
    for (final record in records) {
      if (_dayOnly(record.attendanceDate) != selectedDay) continue;
      _existingAttendanceByStudent[record.studentId] = record;
      _attendanceStatus[record.studentId] = record.status;
      _remarksControllers
              .putIfAbsent(record.studentId, TextEditingController.new)
              .text =
          record.remarks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inheritedAttendanceBloc = _findAttendanceBloc();
    final inheritedStudentBloc = _findStudentBloc();
    return MultiBlocProvider(
      providers: [
        inheritedAttendanceBloc == null
            ? BlocProvider<AttendanceBloc>(
                create: (_) =>
                    sl<AttendanceBloc>()
                      ..add(LoadAttendanceByDateEvent(_selectedDate)),
              )
            : BlocProvider<AttendanceBloc>.value(
                value: inheritedAttendanceBloc,
              ),
        inheritedStudentBloc == null
            ? BlocProvider<StudentBloc>(
                create: (_) =>
                    sl<StudentBloc>()..add(const LoadStudentsEvent()),
              )
            : BlocProvider<StudentBloc>.value(value: inheritedStudentBloc),
      ],
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(_isChoosingClass ? 'Mark Attendance' : _selectedClass!),
            leading: _isChoosingClass
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'All classes',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _selectedClass = null;
                        _selectedSection = null;
                      });
                    },
                  ),
          ),
          floatingActionButton: _isChoosingClass
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _saveAttendance(context),
                  icon: const Icon(Icons.save),
                  label: Text(
                    widget.isEditMode ? 'Update Attendance' : 'Save Attendance',
                  ),
                ),
          body: BlocListener<AttendanceBloc, AttendanceState>(
            listener: (_, state) {
              if (state is AttendanceLoaded) {
                _cacheAttendance(state.attendance);
                if (mounted) setState(() {});
              }
            },
            child: FutureBuilder<AttendanceAcademicStructure>(
              future: _academicStructureFuture,
              builder: (context, structureSnapshot) {
                if (structureSnapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (structureSnapshot.hasError) {
                  return _AcademicStructureLoadError(
                    onRetry: () => setState(
                      () => _academicStructureFuture =
                          AttendanceAcademicStructure.load(
                            _academicStructureRepository,
                          ),
                    ),
                  );
                }
                final structure = structureSnapshot.data!;
                return BlocBuilder<StudentBloc, StudentState>(
                  builder: (context, state) {
                    if (state is StudentLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is StudentError) {
                      return Center(child: Text(state.message));
                    }
                    if (state is! StudentLoaded) return const SizedBox();
                    return _isChoosingClass
                        ? _ClassGrid(
                            classes: structure.classNames,
                            students: state.students,
                            searchController: _searchController,
                            onClassSelected: (className) => _selectClass(
                              context,
                              className,
                              structure.sectionNamesForClass(className),
                            ),
                            onStudentSelected: (student) {
                              _searchController.clear();
                              setState(() {
                                _selectedClass = student.classId;
                                _selectedSection = student.sectionId.isEmpty
                                    ? null
                                    : student.sectionId;
                              });
                            },
                          )
                        : _AttendanceList(
                            className: _selectedClass!,
                            section: _selectedSection,
                            selectedDate: _selectedDate,
                            searchController: _searchController,
                            students: _filteredStudents(state.students),
                            attendanceStatus: _attendanceStatus,
                            remarksControllers: _remarksControllers,
                            onDatePressed: () => _pickDate(context),
                            onStatusChanged: (studentId, status) => setState(
                              () => _attendanceStatus[studentId] = status,
                            ),
                          );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveAttendance(BuildContext context) async {
    final state = context.read<StudentBloc>().state;
    if (state is! StudentLoaded) return;
    final students = _filteredStudents(state.students);
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students found for this class.')),
      );
      return;
    }
    final bloc = context.read<AttendanceBloc>();
    final now = DateTime.now();
    for (final student in students) {
      final existing = _existingAttendanceByStudent[student.id];
      final attendance = AttendanceEntity(
        id:
            existing?.id ??
            '${student.id}_${_selectedDate.year}${_selectedDate.month.toString().padLeft(2, '0')}${_selectedDate.day.toString().padLeft(2, '0')}',
        studentId: student.id,
        admissionNo: student.admissionNo,
        studentName: student.fullName,
        classId: student.classId,
        sectionId: student.sectionId,
        attendanceDate: _selectedDate,
        status: _attendanceStatus[student.id] ?? AttendanceStatus.present,
        remarks: _remarksControllers[student.id]?.text.trim() ?? '',
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      if (existing == null) {
        bloc.add(AddAttendanceEvent(attendance));
      } else {
        bloc.add(UpdateAttendanceEvent(attendance));
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditMode
              ? '${students.length} attendance record(s) updated.'
              : '${students.length} attendance record(s) saved.',
        ),
      ),
    );
  }
}

class _ClassGrid extends StatelessWidget {
  const _ClassGrid({
    required this.classes,
    required this.students,
    required this.searchController,
    required this.onClassSelected,
    required this.onStudentSelected,
  });
  final List<String> classes;
  final List<StudentEntity> students;
  final TextEditingController searchController;
  final ValueChanged<String> onClassSelected;
  final ValueChanged<StudentEntity> onStudentSelected;

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No active classes are available. Add a class from the Classes module first.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 700
            ? 4
            : 2;
        final query = searchController.text.trim().toLowerCase();
        final found = query.isEmpty
            ? const <StudentEntity>[]
            : students
                  .where(
                    (student) =>
                        student.fullName.toLowerCase().contains(query) ||
                        student.admissionNo.toLowerCase().contains(query),
                  )
                  .toList();
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                query.isEmpty ? 'Choose a class' : 'Student search results',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 20),
                  hintText: 'Search any student by name or admission no',
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: searchController.clear,
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: query.isNotEmpty
                    ? _StudentSearchResults(
                        students: found,
                        onStudentSelected: onStudentSelected,
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          childAspectRatio: 2.25,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: classes.length,
                        itemBuilder: (context, index) {
                          final className = classes[index];
                          final count = students
                              .where((student) => student.classId == className)
                              .length;
                          return Card(
                            child: InkWell(
                              onTap: () => onClassSelected(className),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.groups_outlined, size: 20),
                                    const SizedBox(height: 6),
                                    Text(
                                      className,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$count student${count == 1 ? '' : 's'}',
                                    ),
                                  ],
                                ),
                              ),
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
}

class _AcademicStructureLoadError extends StatelessWidget {
  const _AcademicStructureLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 44),
          const SizedBox(height: 12),
          const Text(
            'Unable to load classes. Please check your connection and try again.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    ),
  );
}

class _StudentSearchResults extends StatelessWidget {
  const _StudentSearchResults({
    required this.students,
    required this.onStudentSelected,
  });
  final List<StudentEntity> students;
  final ValueChanged<StudentEntity> onStudentSelected;
  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Center(child: Text('No students match your search.'));
    }
    return ListView.separated(
      itemCount: students.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = students[index];
        final section = student.sectionId.isEmpty
            ? ''
            : ' • Section ${student.sectionId}';
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(student.fullName.isEmpty ? '?' : student.fullName[0]),
            ),
            title: Text(student.fullName),
            subtitle: Text(
              '${student.admissionNo} • ${student.classId}$section',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => onStudentSelected(student),
          ),
        );
      },
    );
  }
}

class _AttendanceList extends StatelessWidget {
  const _AttendanceList({
    required this.className,
    required this.section,
    required this.selectedDate,
    required this.searchController,
    required this.students,
    required this.attendanceStatus,
    required this.remarksControllers,
    required this.onDatePressed,
    required this.onStatusChanged,
  });
  final String className;
  final String? section;
  final DateTime selectedDate;
  final TextEditingController searchController;
  final List<StudentEntity> students;
  final Map<String, AttendanceStatus> attendanceStatus;
  final Map<String, TextEditingController> remarksControllers;
  final VoidCallback onDatePressed;
  final void Function(String, AttendanceStatus) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final title = section == null ? className : '$className • Section $section';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search by student name or admission no',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: onDatePressed,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: students.isEmpty
                ? const Center(child: Text('No students found for this class.'))
                : ListView.separated(
                    itemCount: students.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final status = attendanceStatus.putIfAbsent(
                        student.id,
                        () => AttendanceStatus.present,
                      );
                      final remarks = remarksControllers.putIfAbsent(
                        student.id,
                        TextEditingController.new,
                      );
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final details = _StudentDetails(student: student);
                              final controls = _AttendanceControls(
                                status: status,
                                remarksController: remarks,
                                onStatusChanged: (value) =>
                                    onStatusChanged(student.id, value),
                              );
                              return constraints.maxWidth < 700
                                  ? Column(
                                      children: [
                                        details,
                                        const SizedBox(height: 16),
                                        controls,
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(child: details),
                                        const SizedBox(width: 24),
                                        SizedBox(width: 400, child: controls),
                                      ],
                                    );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StudentDetails extends StatelessWidget {
  const _StudentDetails({required this.student});
  final StudentEntity student;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 24,
        child: Text(
          student.fullName.isEmpty ? '?' : student.fullName[0].toUpperCase(),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.fullName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Roll No: ${student.rollNumber.isEmpty ? '-' : student.rollNumber}',
            ),
            Text('Admission No: ${student.admissionNo}'),
            Text('Father: ${student.fatherName}'),
            if (student.guardianPhone.isNotEmpty)
              Text('Mobile: ${student.guardianPhone}'),
          ],
        ),
      ),
    ],
  );
}

class _AttendanceControls extends StatelessWidget {
  const _AttendanceControls({
    required this.status,
    required this.remarksController,
    required this.onStatusChanged,
  });
  final AttendanceStatus status;
  final TextEditingController remarksController;
  final ValueChanged<AttendanceStatus> onStatusChanged;
  Color _color(AttendanceStatus value) => switch (value) {
    AttendanceStatus.present => Colors.green,
    AttendanceStatus.absent => Colors.red,
    AttendanceStatus.leave => Colors.orange,
    AttendanceStatus.late => Colors.blue,
  };
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: DropdownButtonFormField<AttendanceStatus>(
          key: ValueKey(status),
          initialValue: status,
          decoration: const InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(),
          ),
          items: AttendanceStatus.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    value.name.toUpperCase(),
                    style: TextStyle(
                      color: _color(value),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onStatusChanged(value);
          },
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: TextFormField(
          controller: remarksController,
          decoration: const InputDecoration(
            labelText: 'Remarks',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    ],
  );
}
