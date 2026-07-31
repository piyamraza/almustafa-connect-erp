import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../teachers/domain/entities/teacher_assignment_entity.dart';
import '../../../teachers/domain/repositories/teacher_assignment_repository.dart';
import '../../domain/entities/class_timetable_entry_entity.dart';
import '../../domain/entities/timetable_configuration_entity.dart';
import '../../domain/entities/timetable_period_entity.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../bloc/class_timetable_bloc.dart';
import '../bloc/class_timetable_event.dart';
import '../bloc/class_timetable_state.dart';

class ClassTimetablePage extends StatelessWidget {
  const ClassTimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClassTimetableBloc>(
      create: (_) => sl<ClassTimetableBloc>(),
      child: const _ClassTimetableView(),
    );
  }
}

class _ClassTimetableView extends StatefulWidget {
  const _ClassTimetableView();

  @override
  State<_ClassTimetableView> createState() => _ClassTimetableViewState();
}

class _ClassTimetableViewState extends State<_ClassTimetableView> {
  final _branchController = TextEditingController(text: 'main');
  final _sessionController = TextEditingController(text: '2026-2027');

  List<AcademicClassEntity> _classes = const [];
  List<SectionEntity> _sections = const [];
  List<AcademicSubjectEntity> _subjects = const [];
  List<TeacherAssignmentEntity> _assignments = const [];
  List<ClassTimetableEntryEntity> _cachedEntries = const [];
  TimetableConfigurationEntity? _configuration;
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _referenceError;
  bool _referenceLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadReferenceData();
      }
    });
  }

  @override
  void dispose() {
    _branchController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceData() async {
    final branchId = _branchController.text.trim();
    final academicSession = _sessionController.text.trim();

    if (branchId.isEmpty || academicSession.isEmpty) {
      setState(() {
        _referenceLoading = false;
        _referenceError = 'Branch and academic session are required.';
      });
      return;
    }

    setState(() {
      _referenceLoading = true;
      _referenceError = null;
    });

    try {
      final values = await Future.wait<Object?>([
        sl<AcademicStructureRepository>().getClasses(),
        sl<AcademicStructureRepository>().getSections(),
        sl<AcademicStructureRepository>().getSubjects(),
        sl<TeacherAssignmentRepository>().getAssignments(),
        sl<TimetableRepository>().getConfiguration(
          branchId: branchId,
          academicSession: academicSession,
        ),
      ]);

      if (!mounted) {
        return;
      }

      final classes =
          (values[0] as List<AcademicClassEntity>)
              .where((value) => value.isActive)
              .toList()
            ..sort((first, second) => first.name.compareTo(second.name));
      final sections =
          (values[1] as List<SectionEntity>)
              .where((value) => value.isActive)
              .toList()
            ..sort((first, second) => first.name.compareTo(second.name));
      final subjects =
          (values[2] as List<AcademicSubjectEntity>)
              .where((value) => value.isActive)
              .toList()
            ..sort((first, second) => first.name.compareTo(second.name));
      final assignments = values[3] as List<TeacherAssignmentEntity>;
      final configuration = values[4] as TimetableConfigurationEntity?;

      final classId = classes.isEmpty ? null : classes.first.id;
      final classSections = sections
          .where((value) => value.classId == classId)
          .toList(growable: false);
      final sectionId = classSections.isEmpty ? null : classSections.first.id;

      setState(() {
        _classes = classes;
        _sections = sections;
        _subjects = subjects;
        _assignments = assignments;
        _configuration = configuration;
        _selectedClassId = classId;
        _selectedSectionId = sectionId;
        _cachedEntries = const [];
        _referenceLoading = false;
      });

      if (configuration != null && classId != null && sectionId != null) {
        _loadTimetable();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _referenceLoading = false;
        _referenceError = _message(error);
      });
    }
  }

  void _loadTimetable() {
    final classId = _selectedClassId;
    final sectionId = _selectedSectionId;
    if (_configuration == null || classId == null || sectionId == null) {
      return;
    }

    context.read<ClassTimetableBloc>().add(
      LoadClassTimetableEvent(
        branchId: _branchController.text.trim(),
        academicSession: _sessionController.text.trim(),
        classId: classId,
        sectionId: sectionId,
      ),
    );
  }

  void _selectClass(String? classId) {
    if (classId == null) {
      return;
    }
    final classSections = _sections
        .where((value) => value.classId == classId)
        .toList(growable: false);

    setState(() {
      _selectedClassId = classId;
      _selectedSectionId = classSections.isEmpty
          ? null
          : classSections.first.id;
      _cachedEntries = const [];
    });
    _loadTimetable();
  }

  void _selectSection(String? sectionId) {
    if (sectionId == null) {
      return;
    }
    setState(() {
      _selectedSectionId = sectionId;
      _cachedEntries = const [];
    });
    _loadTimetable();
  }

  List<SectionEntity> get _availableSections {
    final classId = _selectedClassId;
    final values = _sections
        .where((section) => section.classId == classId)
        .toList();
    values.sort((first, second) => first.name.compareTo(second.name));
    return values;
  }

  List<AcademicSubjectEntity> get _availableSubjects {
    final classId = _selectedClassId;
    final sectionId = _selectedSectionId;
    final byName = <String, AcademicSubjectEntity>{};

    for (final subject in _subjects) {
      if (subject.classId == classId && subject.sectionId == null) {
        byName[_normalise(subject.name)] = subject;
      }
    }
    for (final subject in _subjects) {
      if (subject.classId == classId && subject.sectionId == sectionId) {
        byName[_normalise(subject.name)] = subject;
      }
    }

    final values = byName.values.toList()
      ..sort((first, second) => first.name.compareTo(second.name));
    return values;
  }

  List<TeacherAssignmentEntity> _assignmentsForSubject(
    AcademicSubjectEntity subject,
  ) {
    final selectedClass = _selectedClass;
    final selectedSection = _selectedSection;
    if (selectedClass == null || selectedSection == null) {
      return const <TeacherAssignmentEntity>[];
    }

    final academicSession = _normalise(_sessionController.text);
    final subjectName = _normalise(subject.name);
    final byTeacher = <String, TeacherAssignmentEntity>{};

    for (final assignment in _assignments) {
      final classMatches =
          assignment.classId == selectedClass.id ||
          _normalise(assignment.classId) == _normalise(selectedClass.name);
      final sectionMatches =
          assignment.sectionId == selectedSection.id ||
          _normalise(assignment.sectionId) == _normalise(selectedSection.name);
      final sessionMatches =
          _normalise(assignment.academicSession) == academicSession;
      final subjectMatches = _normalise(assignment.subject) == subjectName;

      if (classMatches && sectionMatches && sessionMatches && subjectMatches) {
        byTeacher[assignment.teacherId] = assignment;
      }
    }

    final values = byTeacher.values.toList()
      ..sort(
        (first, second) => first.teacherName.compareTo(second.teacherName),
      );
    return values;
  }

  AcademicClassEntity? get _selectedClass {
    for (final value in _classes) {
      if (value.id == _selectedClassId) {
        return value;
      }
    }
    return null;
  }

  SectionEntity? get _selectedSection {
    for (final value in _sections) {
      if (value.id == _selectedSectionId) {
        return value;
      }
    }
    return null;
  }

  Future<void> _openEntryEditor({
    required int weekday,
    required TimetablePeriodEntity period,
    ClassTimetableEntryEntity? existing,
  }) async {
    final selectedClass = _selectedClass;
    final selectedSection = _selectedSection;
    final subjects = _availableSubjects;

    if (selectedClass == null || selectedSection == null) {
      _showMessage('Select a class and section first.');
      return;
    }
    if (subjects.isEmpty) {
      _showMessage('No active subjects are configured for this class.');
      return;
    }

    final result = await showDialog<_EntryEditorResult>(
      context: context,
      builder: (_) => _EntryEditorDialog(
        weekday: weekday,
        period: period,
        subjects: subjects,
        assignmentsForSubject: _assignmentsForSubject,
        existing: existing,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.action == _EntryEditorAction.delete) {
      if (existing == null || !await _confirmDelete()) {
        return;
      }
      if (!mounted) {
        return;
      }
      context.read<ClassTimetableBloc>().add(
        DeleteClassTimetableEntryEvent(
          entryId: existing.id,
          branchId: existing.branchId,
          academicSession: existing.academicSession,
          classId: existing.classId,
          sectionId: existing.sectionId,
        ),
      );
      return;
    }

    final subject = result.subject;
    final assignment = result.assignment;
    if (subject == null || assignment == null) {
      return;
    }

    final now = DateTime.now();
    final entry = ClassTimetableEntryEntity(
      id:
          existing?.id ??
          sl<TimetableRepository>().generateClassTimetableEntryId(),
      branchId: _branchController.text.trim(),
      academicSession: _sessionController.text.trim(),
      classId: selectedClass.id,
      className: selectedClass.name,
      sectionId: selectedSection.id,
      sectionName: selectedSection.name,
      weekday: weekday,
      periodId: period.id,
      periodLabel: period.label,
      periodOrder: period.order,
      subjectId: subject.id,
      subjectName: subject.name,
      teacherId: assignment.teacherId,
      teacherName: assignment.teacherName,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    context.read<ClassTimetableBloc>().add(SaveClassTimetableEntryEvent(entry));
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remove timetable period?'),
            content: const Text(
              'The selected subject and teacher assignment will be removed '
              'from this timetable slot.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Timetable')),
      body: SafeArea(
        child: BlocConsumer<ClassTimetableBloc, ClassTimetableState>(
          listener: (context, state) {
            if (state is ClassTimetableLoaded) {
              _cachedEntries = state.entries;
              if (state.successMessage != null) {
                _showMessage(state.successMessage!);
              }
            } else if (state is ClassTimetableError) {
              _showMessage(state.message);
            }
          },
          builder: (context, state) {
            final entries = state is ClassTimetableLoaded
                ? state.entries
                : _cachedEntries;
            final isBusy = _referenceLoading || state is ClassTimetableLoading;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class Timetable Builder',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select a class and click any period to assign '
                            'its subject and teacher.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          _buildFilters(isBusy),
                          const SizedBox(height: 20),
                          if (_referenceError != null)
                            _MessageCard(
                              icon: Icons.error_outline,
                              message: _referenceError!,
                              color: Theme.of(context).colorScheme.error,
                            )
                          else if (!_referenceLoading)
                            _buildContent(entries),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isBusy)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters(bool isBusy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 190,
              child: TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(
                  labelText: 'Branch ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 190,
              child: TextFormField(
                controller: _sessionController,
                decoration: const InputDecoration(
                  labelText: 'Academic Session',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                key: ValueKey('class_$_selectedClassId'),
                initialValue: _selectedClassId,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                ),
                items: _classes
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value.id,
                        child: Text(value.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: isBusy ? null : _selectClass,
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                key: ValueKey('section_$_selectedSectionId'),
                initialValue: _selectedSectionId,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  border: OutlineInputBorder(),
                ),
                items: _availableSections
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value.id,
                        child: Text(value.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: isBusy ? null : _selectSection,
              ),
            ),
            FilledButton.icon(
              onPressed: isBusy ? null : _loadReferenceData,
              icon: const Icon(Icons.refresh),
              label: const Text('Load Timetable'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<ClassTimetableEntryEntity> entries) {
    final configuration = _configuration;
    if (configuration == null) {
      return const _MessageCard(
        icon: Icons.settings_outlined,
        message:
            'Timetable configuration was not found. Complete Timetable '
            'Configuration for this branch and session first.',
        color: Color(0xFFF57C00),
      );
    }
    if (_classes.isEmpty) {
      return const _MessageCard(
        icon: Icons.school_outlined,
        message: 'No active classes are available.',
        color: Color(0xFFF57C00),
      );
    }
    if (_selectedSectionId == null) {
      return const _MessageCard(
        icon: Icons.segment_outlined,
        message: 'No active section is available for the selected class.',
        color: Color(0xFFF57C00),
      );
    }

    final periods = configuration.orderedPeriods
        .where((period) => period.isTeaching)
        .toList(growable: false);
    final days = configuration.workingDays.toList()..sort();

    if (periods.isEmpty || days.isEmpty) {
      return const _MessageCard(
        icon: Icons.event_busy_outlined,
        message: 'No teaching periods or working days are configured.',
        color: Color(0xFFF57C00),
      );
    }

    final bySlot = <String, ClassTimetableEntryEntity>{
      for (final entry in entries) '${entry.weekday}|${entry.periodId}': entry,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(Icons.view_week_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_selectedClass?.name ?? ''} - '
                    '${_selectedSection?.name ?? ''}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text('${entries.length} assigned periods'),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 165 + (days.length * 190),
              child: Table(
                border: TableBorder.all(color: Theme.of(context).dividerColor),
                columnWidths: <int, TableColumnWidth>{
                  0: const FixedColumnWidth(165),
                  for (var index = 1; index <= days.length; index++)
                    index: const FixedColumnWidth(190),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    children: [
                      _headerCell('Period'),
                      for (final day in days) _headerCell(_dayName(day)),
                    ],
                  ),
                  for (final period in periods)
                    TableRow(
                      children: [
                        _periodCell(period),
                        for (final day in days)
                          _scheduleCell(
                            weekday: day,
                            period: period,
                            entry: bySlot['$day|${period.id}'],
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label) {
    return Container(
      height: 54,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _periodCell(TimetablePeriodEntity period) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(12),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            '${_formatMinutes(period.startMinutes)} - '
            '${_formatMinutes(period.endMinutes)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _scheduleCell({
    required int weekday,
    required TimetablePeriodEntity period,
    required ClassTimetableEntryEntity? entry,
  }) {
    return SizedBox(
      height: 112,
      child: InkWell(
        onTap: () =>
            _openEntryEditor(weekday: weekday, period: period, existing: entry),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: entry == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Assign',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.subjectName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.edit_outlined, size: 17),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            entry.teacherName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _dayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Monday',
      DateTime.tuesday => 'Tuesday',
      DateTime.wednesday => 'Wednesday',
      DateTime.thursday => 'Thursday',
      DateTime.friday => 'Friday',
      DateTime.saturday => 'Saturday',
      DateTime.sunday => 'Sunday',
      _ => 'Day',
    };
  }

  String _formatMinutes(int value) {
    final hour = value ~/ 60;
    final minute = value % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');

  static String _normalise(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

class _EntryEditorDialog extends StatefulWidget {
  const _EntryEditorDialog({
    required this.weekday,
    required this.period,
    required this.subjects,
    required this.assignmentsForSubject,
    this.existing,
  });

  final int weekday;
  final TimetablePeriodEntity period;
  final List<AcademicSubjectEntity> subjects;
  final List<TeacherAssignmentEntity> Function(AcademicSubjectEntity subject)
  assignmentsForSubject;
  final ClassTimetableEntryEntity? existing;

  @override
  State<_EntryEditorDialog> createState() => _EntryEditorDialogState();
}

class _EntryEditorDialogState extends State<_EntryEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSubjectId;
  String? _selectedTeacherId;

  @override
  void initState() {
    super.initState();
    final existingSubjectId = widget.existing?.subjectId;
    final hasExistingSubject = widget.subjects.any(
      (subject) => subject.id == existingSubjectId,
    );
    _selectedSubjectId = hasExistingSubject
        ? existingSubjectId
        : widget.subjects.first.id;

    final assignments = _availableAssignments;
    final existingTeacherId = widget.existing?.teacherId;
    final hasExistingTeacher = assignments.any(
      (assignment) => assignment.teacherId == existingTeacherId,
    );
    _selectedTeacherId = hasExistingTeacher
        ? existingTeacherId
        : assignments.isEmpty
        ? null
        : assignments.first.teacherId;
  }

  AcademicSubjectEntity? get _selectedSubject {
    for (final subject in widget.subjects) {
      if (subject.id == _selectedSubjectId) {
        return subject;
      }
    }
    return null;
  }

  List<TeacherAssignmentEntity> get _availableAssignments {
    final subject = _selectedSubject;
    return subject == null
        ? const <TeacherAssignmentEntity>[]
        : widget.assignmentsForSubject(subject);
  }

  TeacherAssignmentEntity? get _selectedAssignment {
    for (final assignment in _availableAssignments) {
      if (assignment.teacherId == _selectedTeacherId) {
        return assignment;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final assignments = _availableAssignments;

    return AlertDialog(
      title: Text(widget.existing == null ? 'Assign Period' : 'Edit Period'),
      content: SizedBox(
        width: 470,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_dayName(widget.weekday)} - ${widget.period.label}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                key: ValueKey('dialog_subject_$_selectedSubjectId'),
                initialValue: _selectedSubjectId,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                items: widget.subjects
                    .map(
                      (subject) => DropdownMenuItem<String>(
                        value: subject.id,
                        child: Text(subject.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _selectedSubjectId = value;
                    final available = _availableAssignments;
                    _selectedTeacherId = available.isEmpty
                        ? null
                        : available.first.teacherId;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select a subject.' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'dialog_teacher_${_selectedSubjectId}_$_selectedTeacherId',
                ),
                initialValue: _selectedTeacherId,
                decoration: InputDecoration(
                  labelText: 'Teacher',
                  border: const OutlineInputBorder(),
                  helperText: assignments.isEmpty
                      ? 'Assign a teacher to this subject first.'
                      : null,
                ),
                items: assignments
                    .map(
                      (assignment) => DropdownMenuItem<String>(
                        value: assignment.teacherId,
                        child: Text(assignment.teacherName),
                      ),
                    )
                    .toList(growable: false),
                onChanged: assignments.isEmpty
                    ? null
                    : (value) => setState(() => _selectedTeacherId = value),
                validator: (value) =>
                    value == null ? 'Select a teacher.' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton.icon(
            onPressed: () =>
                Navigator.pop(context, const _EntryEditorResult.delete()),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.pop(
              context,
              _EntryEditorResult.save(
                subject: _selectedSubject!,
                assignment: _selectedAssignment!,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _dayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Monday',
      DateTime.tuesday => 'Tuesday',
      DateTime.wednesday => 'Wednesday',
      DateTime.thursday => 'Thursday',
      DateTime.friday => 'Friday',
      DateTime.saturday => 'Saturday',
      DateTime.sunday => 'Sunday',
      _ => 'Day',
    };
  }
}

enum _EntryEditorAction { save, delete }

class _EntryEditorResult {
  const _EntryEditorResult.save({
    required this.subject,
    required this.assignment,
  }) : action = _EntryEditorAction.save;

  const _EntryEditorResult.delete()
    : action = _EntryEditorAction.delete,
      subject = null,
      assignment = null;

  final _EntryEditorAction action;
  final AcademicSubjectEntity? subject;
  final TeacherAssignmentEntity? assignment;
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 14),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
