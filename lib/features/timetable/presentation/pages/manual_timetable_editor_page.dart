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
import '../../domain/entities/manual_timetable_change_entity.dart';
import '../../domain/entities/timetable_configuration_entity.dart';
import '../../domain/entities/timetable_period_entity.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../bloc/manual_timetable_bloc.dart';

class ManualTimetableEditorPage extends StatelessWidget {
  const ManualTimetableEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ManualTimetableBloc>(
      create: (_) => sl<ManualTimetableBloc>(),
      child: const _ManualTimetableEditorView(),
    );
  }
}

class _ManualTimetableEditorView extends StatefulWidget {
  const _ManualTimetableEditorView();

  @override
  State<_ManualTimetableEditorView> createState() =>
      _ManualTimetableEditorViewState();
}

class _ManualTimetableEditorViewState
    extends State<_ManualTimetableEditorView> {
  final _branchController = TextEditingController(text: 'main');
  final _sessionController = TextEditingController(text: '2026-2027');

  List<AcademicClassEntity> _classes = const [];
  List<SectionEntity> _sections = const [];
  List<AcademicSubjectEntity> _subjects = const [];
  List<TeacherAssignmentEntity> _assignments = const [];
  List<ClassTimetableEntryEntity> _allSessionEntries = const [];
  TimetableConfigurationEntity? _configuration;

  String? _selectedClassId;
  String? _selectedSectionId;
  String? _referenceError;
  bool _referenceLoading = true;

  List<ClassTimetableEntryEntity> _originalEntries = const [];
  List<ClassTimetableEntryEntity> _draftEntries = const [];
  final List<List<ClassTimetableEntryEntity>> _undoStack = [];
  final List<List<ClassTimetableEntryEntity>> _redoStack = [];

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
    setState(() {
      _referenceLoading = true;
      _referenceError = null;
    });

    try {
      final branchId = _branchController.text.trim();
      final session = _sessionController.text.trim();
      final values = await Future.wait<Object?>([
        sl<AcademicStructureRepository>().getClasses(),
        sl<AcademicStructureRepository>().getSections(),
        sl<AcademicStructureRepository>().getSubjects(),
        sl<TeacherAssignmentRepository>().getAssignments(),
        sl<TimetableRepository>().getConfiguration(
          branchId: branchId,
          academicSession: session,
        ),
        sl<TimetableRepository>().getAllTimetableEntries(
          branchId: branchId,
          academicSession: session,
        ),
      ]);

      if (!mounted) {
        return;
      }

      final classes =
          (values[0] as List<AcademicClassEntity>)
              .where((item) => item.isActive)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      final sections =
          (values[1] as List<SectionEntity>)
              .where((item) => item.isActive)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      final subjects =
          (values[2] as List<AcademicSubjectEntity>)
              .where((item) => item.isActive)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      final classId = classes.isEmpty ? null : classes.first.id;
      final classSections = sections
          .where((item) => item.classId == classId)
          .toList(growable: false);

      setState(() {
        _classes = classes;
        _sections = sections;
        _subjects = subjects;
        _assignments = values[3] as List<TeacherAssignmentEntity>;
        _configuration = values[4] as TimetableConfigurationEntity?;
        _allSessionEntries = values[5] as List<ClassTimetableEntryEntity>;
        _selectedClassId = classId;
        _selectedSectionId = classSections.isEmpty
            ? null
            : classSections.first.id;
        _referenceLoading = false;
      });

      _loadSelectedClass();
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

  void _loadSelectedClass() {
    final classId = _selectedClassId;
    final sectionId = _selectedSectionId;
    if (classId == null || sectionId == null || _configuration == null) {
      return;
    }

    context.read<ManualTimetableBloc>().add(
      LoadManualTimetable(
        branchId: _branchController.text.trim(),
        academicSession: _sessionController.text.trim(),
        classId: classId,
        sectionId: sectionId,
      ),
    );
  }

  List<SectionEntity> get _availableSections {
    final values = _sections
        .where((section) => section.classId == _selectedClassId)
        .toList();
    values.sort((a, b) => a.name.compareTo(b.name));
    return values;
  }

  AcademicClassEntity? get _selectedClass {
    for (final item in _classes) {
      if (item.id == _selectedClassId) return item;
    }
    return null;
  }

  SectionEntity? get _selectedSection {
    for (final item in _sections) {
      if (item.id == _selectedSectionId) return item;
    }
    return null;
  }

  void _setLoadedEntries(List<ClassTimetableEntryEntity> entries) {
    _originalEntries = List<ClassTimetableEntryEntity>.of(entries);
    _draftEntries = List<ClassTimetableEntryEntity>.of(entries);
    _undoStack.clear();
    _redoStack.clear();
  }

  void _pushHistory() {
    _undoStack.add(List<ClassTimetableEntryEntity>.of(_draftEntries));
    if (_undoStack.length > 30) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _redoStack.add(List<ClassTimetableEntryEntity>.of(_draftEntries));
      _draftEntries = _undoStack.removeLast();
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _undoStack.add(List<ClassTimetableEntryEntity>.of(_draftEntries));
      _draftEntries = _redoStack.removeLast();
    });
  }

  ClassTimetableEntryEntity? _entryAt(int weekday, String periodId) {
    for (final entry in _draftEntries) {
      if (entry.weekday == weekday && entry.periodId == periodId) {
        return entry;
      }
    }
    return null;
  }

  Future<void> _dropEntry(
    ClassTimetableEntryEntity source,
    int targetDay,
    TimetablePeriodEntity targetPeriod,
  ) async {
    if (source.weekday == targetDay && source.periodId == targetPeriod.id) {
      return;
    }

    final target = _entryAt(targetDay, targetPeriod.id);
    final movedSource = source.copyWith(
      weekday: targetDay,
      periodId: targetPeriod.id,
      periodLabel: targetPeriod.label,
      periodOrder: targetPeriod.order,
      updatedAt: DateTime.now(),
    );
    final movedTarget = target?.copyWith(
      weekday: source.weekday,
      periodId: source.periodId,
      periodLabel: source.periodLabel,
      periodOrder: source.periodOrder,
      updatedAt: DateTime.now(),
    );

    final candidate = List<ClassTimetableEntryEntity>.of(_draftEntries)
      ..removeWhere((item) => item.id == source.id || item.id == target?.id)
      ..add(movedSource);
    if (movedTarget != null) {
      candidate.add(movedTarget);
    }

    final conflict = _firstConflict(candidate);
    if (conflict != null) {
      _showMessage(conflict);
      return;
    }

    setState(() {
      _pushHistory();
      _draftEntries = candidate;
    });
  }

  String? _firstConflict(List<ClassTimetableEntryEntity> candidate) {
    final currentClassIds = _originalEntries.map((item) => item.id).toSet();
    final externalEntries = _allSessionEntries
        .where((item) => !currentClassIds.contains(item.id))
        .toList(growable: false);

    final classSlots = <String>{};
    final teacherSlots = <String, ClassTimetableEntryEntity>{};

    for (final entry in candidate) {
      final classKey = '${entry.weekday}|${entry.periodId}';
      if (!classSlots.add(classKey)) {
        return 'This class already has another assignment in that slot.';
      }

      final teacherKey =
          '${entry.teacherId}|${entry.weekday}|${entry.periodId}';
      final existingTeacher = teacherSlots[teacherKey];
      if (existingTeacher != null) {
        return '${entry.teacherName} would be double-booked.';
      }
      teacherSlots[teacherKey] = entry;
    }

    for (final entry in candidate) {
      for (final external in externalEntries) {
        if (external.teacherId == entry.teacherId &&
            external.weekday == entry.weekday &&
            external.periodId == entry.periodId) {
          return '${entry.teacherName} is already assigned to '
              '${external.className} - ${external.sectionName} in '
              '${entry.periodLabel}.';
        }
      }
    }

    return null;
  }

  Future<void> _editEntry(
    int weekday,
    TimetablePeriodEntity period,
    ClassTimetableEntryEntity? existing,
  ) async {
    final subjects = _subjectsForSelection;
    if (subjects.isEmpty) {
      _showMessage('No active subjects are available for this class.');
      return;
    }

    final result = await showDialog<_EditorResult>(
      context: context,
      builder: (_) => _EditorDialog(
        weekday: weekday,
        period: period,
        subjects: subjects,
        assignmentsForSubject: _assignmentsForSubject,
        existing: existing,
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _pushHistory();

      if (result.remove) {
        _draftEntries = _draftEntries
            .where((item) => item.id != existing?.id)
            .toList(growable: false);
        return;
      }

      final subject = result.subject!;
      final assignment = result.assignment!;
      final now = DateTime.now();
      final entry = ClassTimetableEntryEntity(
        id:
            existing?.id ??
            sl<TimetableRepository>().generateClassTimetableEntryId(),
        branchId: _branchController.text.trim(),
        academicSession: _sessionController.text.trim(),
        classId: _selectedClass!.id,
        className: _selectedClass!.name,
        sectionId: _selectedSection!.id,
        sectionName: _selectedSection!.name,
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

      final candidate =
          _draftEntries.where((item) => item.id != existing?.id).toList()
            ..add(entry);

      final conflict = _firstConflict(candidate);
      if (conflict != null) {
        _undoStack.removeLast();
        _showMessage(conflict);
        return;
      }

      _draftEntries = candidate;
    });
  }

  List<AcademicSubjectEntity> get _subjectsForSelection {
    final byName = <String, AcademicSubjectEntity>{};
    for (final subject in _subjects) {
      if (subject.classId == _selectedClassId && subject.sectionId == null) {
        byName[_normalise(subject.name)] = subject;
      }
    }
    for (final subject in _subjects) {
      if (subject.classId == _selectedClassId &&
          subject.sectionId == _selectedSectionId) {
        byName[_normalise(subject.name)] = subject;
      }
    }
    return byName.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  List<TeacherAssignmentEntity> _assignmentsForSubject(
    AcademicSubjectEntity subject,
  ) {
    final selectedClass = _selectedClass;
    final selectedSection = _selectedSection;
    if (selectedClass == null || selectedSection == null) return const [];

    final values = _assignments.where((assignment) {
      final classMatches =
          assignment.classId == selectedClass.id ||
          _normalise(assignment.classId) == _normalise(selectedClass.name);
      final sectionMatches =
          assignment.sectionId == selectedSection.id ||
          _normalise(assignment.sectionId) == _normalise(selectedSection.name);
      return classMatches &&
          sectionMatches &&
          _normalise(assignment.subject) == _normalise(subject.name) &&
          _normalise(assignment.academicSession) ==
              _normalise(_sessionController.text);
    }).toList();

    values.sort((a, b) => a.teacherName.compareTo(b.teacherName));
    return values;
  }

  void _saveChanges() {
    final conflict = _firstConflict(_draftEntries);
    if (conflict != null) {
      _showMessage(conflict);
      return;
    }

    final originalIds = _originalEntries.map((item) => item.id).toSet();
    final draftIds = _draftEntries.map((item) => item.id).toSet();
    final deletedIds = originalIds.difference(draftIds).toList();

    context.read<ManualTimetableBloc>().add(
      SaveManualTimetable(
        ManualTimetableChangeSet(
          branchId: _branchController.text.trim(),
          academicSession: _sessionController.text.trim(),
          classId: _selectedClassId!,
          sectionId: _selectedSectionId!,
          deletedEntryIds: deletedIds,
          entries: _draftEntries,
        ),
      ),
    );
  }

  bool get _hasChanges {
    if (_originalEntries.length != _draftEntries.length) return true;
    final original = {for (final item in _originalEntries) item.id: item};
    for (final item in _draftEntries) {
      if (original[item.id] != item) return true;
    }
    return false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Timetable Editor')),
      body: SafeArea(
        child: BlocConsumer<ManualTimetableBloc, ManualTimetableState>(
          listener: (context, state) {
            if (state is ManualTimetableLoaded) {
              setState(() {
                _setLoadedEntries(state.entries);
              });
              if (state.successMessage != null) {
                _showMessage(state.successMessage!);
              }
            } else if (state is ManualTimetableError) {
              _showMessage(state.message);
            }
          },
          builder: (context, state) {
            final busy = _referenceLoading || state is ManualTimetableLoading;

            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildToolbar(busy),
                      const SizedBox(height: 12),
                      if (_referenceError != null)
                        _MessageCard(
                          message: _referenceError!,
                          color: Theme.of(context).colorScheme.error,
                        )
                      else
                        Expanded(child: _buildGrid()),
                    ],
                  ),
                ),
                if (busy)
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

  Widget _buildToolbar(bool busy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 150,
              child: TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(
                  labelText: 'Branch',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(
              width: 170,
              child: TextFormField(
                controller: _sessionController,
                decoration: const InputDecoration(
                  labelText: 'Session',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedClassId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _classes
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) {
                        final sections = _sections
                            .where((item) => item.classId == value)
                            .toList();
                        setState(() {
                          _selectedClassId = value;
                          _selectedSectionId = sections.isEmpty
                              ? null
                              : sections.first.id;
                        });
                        _loadSelectedClass();
                      },
              ),
            ),
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedSectionId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _availableSections
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) {
                        setState(() => _selectedSectionId = value);
                        _loadSelectedClass();
                      },
              ),
            ),
            IconButton.filledTonal(
              onPressed: _undoStack.isEmpty ? null : _undo,
              tooltip: 'Undo',
              icon: const Icon(Icons.undo),
            ),
            IconButton.filledTonal(
              onPressed: _redoStack.isEmpty ? null : _redo,
              tooltip: 'Redo',
              icon: const Icon(Icons.redo),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : _loadReferenceData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
            FilledButton.icon(
              onPressed: busy || !_hasChanges ? null : _saveChanges,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final config = _configuration;
    if (config == null) {
      return const _MessageCard(
        message: 'Timetable configuration was not found.',
        color: Color(0xFFF57C00),
      );
    }

    final periods = config.orderedPeriods
        .where((item) => item.isTeaching)
        .toList();
    final days = config.workingDays.toList()..sort();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dayWidth = 105.0;
          const periodWidth = 155.0;
          final width = dayWidth + periods.length * periodWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Table(
                border: TableBorder.all(color: Theme.of(context).dividerColor),
                columnWidths: {
                  0: const FixedColumnWidth(dayWidth),
                  for (var i = 1; i <= periods.length; i++)
                    i: const FixedColumnWidth(periodWidth),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    children: [
                      _header('Day'),
                      for (final period in periods) _periodHeader(period),
                    ],
                  ),
                  for (final day in days)
                    TableRow(
                      children: [
                        _dayCell(day),
                        for (final period in periods) _slot(day, period),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(String text) => Container(
    height: 58,
    alignment: Alignment.center,
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  Widget _periodHeader(TimetablePeriodEntity period) => Container(
    height: 58,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(5),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          period.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(
          '${_formatMinutes(period.startMinutes)} - '
          '${_formatMinutes(period.endMinutes)}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    ),
  );

  Widget _dayCell(int day) => Container(
    height: 88,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Text(
      _dayName(day),
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );

  Widget _slot(int day, TimetablePeriodEntity period) {
    final entry = _entryAt(day, period.id);

    return DragTarget<ClassTimetableEntryEntity>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => _dropEntry(details.data, day, period),
      builder: (context, candidates, rejects) {
        final highlighted = candidates.isNotEmpty;
        return Container(
          height: 88,
          color: highlighted
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: InkWell(
            onTap: () => _editEntry(day, period, entry),
            child: entry == null
                ? const Center(child: Icon(Icons.add_circle_outline))
                : LongPressDraggable<ClassTimetableEntryEntity>(
                    data: entry,
                    feedback: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(width: 150, child: _entryContent(entry)),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.25,
                      child: _entryContent(entry),
                    ),
                    child: _entryContent(entry),
                  ),
          ),
        );
      },
    );
  }

  Widget _entryContent(ClassTimetableEntryEntity entry) => Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.subjectName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          entry.teacherName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10),
        ),
        const SizedBox(height: 3),
        const Row(
          children: [
            Icon(Icons.drag_indicator, size: 13),
            SizedBox(width: 3),
            Text('Hold & drag', style: TextStyle(fontSize: 9)),
          ],
        ),
      ],
    ),
  );

  String _dayName(int day) => switch (day) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    DateTime.sunday => 'Sunday',
    _ => 'Day',
  };

  String _formatMinutes(int value) {
    final hour = value ~/ 60;
    final minute = value % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$display:${minute.toString().padLeft(2, '0')} $suffix';
  }

  String _normalise(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}

class _EditorDialog extends StatefulWidget {
  const _EditorDialog({
    required this.weekday,
    required this.period,
    required this.subjects,
    required this.assignmentsForSubject,
    this.existing,
  });

  final int weekday;
  final TimetablePeriodEntity period;
  final List<AcademicSubjectEntity> subjects;
  final List<TeacherAssignmentEntity> Function(AcademicSubjectEntity)
  assignmentsForSubject;
  final ClassTimetableEntryEntity? existing;

  @override
  State<_EditorDialog> createState() => _EditorDialogState();
}

class _EditorDialogState extends State<_EditorDialog> {
  String? _subjectId;
  String? _teacherId;

  @override
  void initState() {
    super.initState();
    _subjectId =
        widget.subjects.any((item) => item.id == widget.existing?.subjectId)
        ? widget.existing?.subjectId
        : widget.subjects.first.id;
    final assignments = _assignments;
    _teacherId =
        assignments.any((item) => item.teacherId == widget.existing?.teacherId)
        ? widget.existing?.teacherId
        : assignments.isEmpty
        ? null
        : assignments.first.teacherId;
  }

  AcademicSubjectEntity get _subject =>
      widget.subjects.firstWhere((item) => item.id == _subjectId);

  List<TeacherAssignmentEntity> get _assignments =>
      widget.assignmentsForSubject(_subject);

  TeacherAssignmentEntity? get _assignment {
    for (final item in _assignments) {
      if (item.teacherId == _teacherId) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Assign Period' : 'Edit Period'),
      content: SizedBox(
        width: 470,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _subjectId,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
              items: widget.subjects
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _subjectId = value;
                  final assignments = _assignments;
                  _teacherId = assignments.isEmpty
                      ? null
                      : assignments.first.teacherId;
                });
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _teacherId,
              decoration: InputDecoration(
                labelText: 'Teacher',
                border: const OutlineInputBorder(),
                helperText: _assignments.isEmpty
                    ? 'No teacher assignment exists for this subject.'
                    : null,
              ),
              items: _assignments
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.teacherId,
                      child: Text(item.teacherName),
                    ),
                  )
                  .toList(),
              onChanged: _assignments.isEmpty
                  ? null
                  : (value) => setState(() => _teacherId = value),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton.icon(
            onPressed: () =>
                Navigator.pop(context, const _EditorResult.remove()),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _assignment == null
              ? null
              : () => Navigator.pop(
                  context,
                  _EditorResult.save(_subject, _assignment!),
                ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _EditorResult {
  const _EditorResult.save(this.subject, this.assignment) : remove = false;
  const _EditorResult.remove()
    : remove = true,
      subject = null,
      assignment = null;

  final bool remove;
  final AcademicSubjectEntity? subject;
  final TeacherAssignmentEntity? assignment;
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
