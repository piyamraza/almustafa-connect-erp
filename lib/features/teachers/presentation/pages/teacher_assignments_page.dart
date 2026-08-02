import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../domain/entities/teacher_assignment_entity.dart';
import '../../domain/entities/teacher_entity.dart';
import '../../domain/repositories/teacher_assignment_repository.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../bloc/teacher_assignment_bloc.dart';

class TeacherAssignmentsPage extends StatelessWidget {
  const TeacherAssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeacherAssignmentBloc>(
      create: (_) =>
          sl<TeacherAssignmentBloc>()..add(const LoadTeacherAssignments()),
      child: const _AssignmentsView(),
    );
  }
}

class _AssignmentsView extends StatefulWidget {
  const _AssignmentsView();

  @override
  State<_AssignmentsView> createState() => _AssignmentsViewState();
}

class _AssignmentsViewState extends State<_AssignmentsView> {
  final _sessionController = TextEditingController(
    text: '${DateTime.now().year}-${DateTime.now().year + 1}',
  );
  late final Future<_AssignmentOptions> _optionsFuture;
  String? _classId;
  String? _sectionId;

  @override
  void initState() {
    super.initState();
    _optionsFuture = _loadOptions();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  Future<_AssignmentOptions> _loadOptions() async {
    final academic = sl<AcademicStructureRepository>();
    final values = await Future.wait<Object>([
      sl<TeacherRepository>().getTeachers(),
      academic.getClasses(),
      academic.getSections(),
      academic.getSubjects(),
    ]);
    final teachers =
        (values[0] as List<TeacherEntity>)
            .where((item) => item.isActive)
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
    final classes =
        (values[1] as List<AcademicClassEntity>)
            .where((item) => item.isActive)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final sections =
        (values[2] as List<SectionEntity>)
            .where((item) => item.isActive)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final subjects =
        (values[3] as List<AcademicSubjectEntity>)
            .where((item) => item.isActive)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return _AssignmentOptions(
      teachers: teachers,
      classes: classes,
      sections: sections,
      subjects: subjects,
    );
  }

  void _ensureSelection(_AssignmentOptions options) {
    if (!options.classes.any((item) => item.id == _classId)) {
      _classId = options.classes.firstOrNull?.id;
      _sectionId = null;
    }
    final sections = options.sectionsFor(_classId);
    if (!sections.any((item) => item.id == _sectionId)) {
      _sectionId = sections.firstOrNull?.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Assignments'),
        actions: const [DashboardNavigationButton()],
      ),
      body: FutureBuilder<_AssignmentOptions>(
        future: _optionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(_message(snapshot.error!)));
          }
          final options = snapshot.data!;
          _ensureSelection(options);
          return BlocConsumer<TeacherAssignmentBloc, TeacherAssignmentState>(
            listener: (context, state) {
              if (state is TeacherAssignmentError) {
                _show(state.message);
              }
            },
            builder: (context, state) {
              final assignments = switch (state) {
                TeacherAssignmentLoaded(:final assignments) => assignments,
                TeacherAssignmentError(:final assignments) => assignments,
                _ => const <TeacherAssignmentEntity>[],
              };
              final busy = state is TeacherAssignmentLoading;
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _toolbar(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 760) {
                                return Column(
                                  children: [
                                    SizedBox(
                                      height: 76,
                                      child: _classSelector(
                                        options,
                                        horizontal: true,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: _subjectsPanel(
                                        options,
                                        assignments,
                                        busy,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: 230,
                                    child: _classSelector(options),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _subjectsPanel(
                                      options,
                                      assignments,
                                      busy,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
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
          );
        },
      ),
    );
  }

  Widget _toolbar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.account_tree_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Select a class and subject, then assign a teacher.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(
              width: 190,
              child: TextField(
                controller: _sessionController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Academic Session',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _classSelector(_AssignmentOptions options, {bool horizontal = false}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!horizontal)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Classes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          Expanded(
            child: options.classes.isEmpty
                ? const Center(child: Text('No active classes.'))
                : ListView.separated(
                    scrollDirection: horizontal
                        ? Axis.horizontal
                        : Axis.vertical,
                    padding: const EdgeInsets.all(8),
                    itemCount: options.classes.length,
                    separatorBuilder: (_, _) => SizedBox(
                      width: horizontal ? 8 : 0,
                      height: horizontal ? 0 : 4,
                    ),
                    itemBuilder: (context, index) {
                      final academicClass = options.classes[index];
                      final selected = academicClass.id == _classId;
                      if (horizontal) {
                        return ChoiceChip(
                          selected: selected,
                          label: Text(academicClass.name),
                          onSelected: (_) =>
                              _selectClass(options, academicClass),
                        );
                      }
                      return ListTile(
                        selected: selected,
                        selectedTileColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        leading: const Icon(Icons.school_outlined),
                        title: Text(academicClass.name),
                        trailing: const Icon(Icons.chevron_right),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onTap: () => _selectClass(options, academicClass),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _selectClass(
    _AssignmentOptions options,
    AcademicClassEntity academicClass,
  ) {
    setState(() {
      _classId = academicClass.id;
      _sectionId = options.sectionsFor(academicClass.id).firstOrNull?.id;
    });
  }

  Widget _subjectsPanel(
    _AssignmentOptions options,
    List<TeacherAssignmentEntity> assignments,
    bool busy,
  ) {
    final academicClass = options.classById(_classId);
    final sections = options.sectionsFor(_classId);
    final section = options.sectionById(_sectionId);
    final subjects = options.subjectsFor(_classId, _sectionId);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  academicClass == null
                      ? 'Subjects'
                      : '${academicClass.name} Subjects',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (sections.isEmpty)
                  const Text('No active sections are available for this class.')
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      segments: [
                        for (final item in sections)
                          ButtonSegment(value: item.id, label: Text(item.name)),
                      ],
                      selected: {?_sectionId},
                      onSelectionChanged: busy
                          ? null
                          : (values) =>
                                setState(() => _sectionId = values.firstOrNull),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Subject')),
                Expanded(flex: 4, child: Text('Assigned Teacher')),
                SizedBox(width: 120, child: Text('Action')),
              ],
            ),
          ),
          Expanded(
            child: section == null
                ? const Center(child: Text('Select a section.'))
                : subjects.isEmpty
                ? const Center(child: Text('No active subjects found.'))
                : ListView.separated(
                    itemCount: subjects.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      final assignment = _assignmentFor(
                        assignments,
                        academicClass!,
                        section,
                        subject,
                      );
                      return InkWell(
                        onTap: busy
                            ? null
                            : () => _openTeacherDialog(
                                options: options,
                                academicClass: academicClass,
                                section: section,
                                subject: subject,
                                assignment: assignment,
                              ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  subject.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: assignment == null
                                    ? Text(
                                        'Not assigned',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 7),
                                          Flexible(
                                            child: Text(
                                              assignment.teacherName,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (assignment.isClassTeacher)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Chip(
                                                label: Text('Class Teacher'),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            ),
                                        ],
                                      ),
                              ),
                              SizedBox(
                                width: 120,
                                child: OutlinedButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => _openTeacherDialog(
                                          options: options,
                                          academicClass: academicClass,
                                          section: section,
                                          subject: subject,
                                          assignment: assignment,
                                        ),
                                  icon: Icon(
                                    assignment == null
                                        ? Icons.person_add_alt
                                        : Icons.edit_outlined,
                                  ),
                                  label: Text(
                                    assignment == null ? 'Assign' : 'Edit',
                                  ),
                                ),
                              ),
                            ],
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

  TeacherAssignmentEntity? _assignmentFor(
    List<TeacherAssignmentEntity> assignments,
    AcademicClassEntity academicClass,
    SectionEntity section,
    AcademicSubjectEntity subject,
  ) {
    final session = _normalise(_sessionController.text);
    for (final assignment in assignments) {
      final classMatches =
          assignment.classId == academicClass.id ||
          _normalise(assignment.classId) == _normalise(academicClass.name);
      final sectionMatches =
          assignment.sectionId == section.id ||
          _normalise(assignment.sectionId) == _normalise(section.name);
      if (_normalise(assignment.academicSession) == session &&
          classMatches &&
          sectionMatches &&
          _normalise(assignment.subject) == _normalise(subject.name)) {
        return assignment;
      }
    }
    return null;
  }

  Future<void> _openTeacherDialog({
    required _AssignmentOptions options,
    required AcademicClassEntity academicClass,
    required SectionEntity section,
    required AcademicSubjectEntity subject,
    required TeacherAssignmentEntity? assignment,
  }) async {
    TeacherEntity? selected = options.teachers
        .where((item) => item.id == assignment?.teacherId)
        .firstOrNull;
    var classTeacher = assignment?.isClassTeacher ?? false;
    final result = await showDialog<_TeacherChoice>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            '${subject.name} • ${academicClass.name}-${section.name}',
          ),
          content: SizedBox(
            width: 520,
            height: 460,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Teacher'),
                const SizedBox(height: 8),
                Expanded(
                  child: options.teachers.isEmpty
                      ? const Center(child: Text('No active teachers found.'))
                      : RadioGroup<TeacherEntity>(
                          groupValue: selected,
                          onChanged: (value) =>
                              setDialogState(() => selected = value),
                          child: ListView.builder(
                            itemCount: options.teachers.length,
                            itemBuilder: (context, index) {
                              final teacher = options.teachers[index];
                              return RadioListTile<TeacherEntity>(
                                value: teacher,
                                title: Text(teacher.fullName),
                                subtitle: teacher.designation.trim().isEmpty
                                    ? null
                                    : Text(teacher.designation),
                              );
                            },
                          ),
                        ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: classTeacher,
                  title: const Text('Also assign as class teacher'),
                  onChanged: (value) =>
                      setDialogState(() => classTeacher = value),
                ),
              ],
            ),
          ),
          actions: [
            if (assignment != null)
              TextButton.icon(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  const _TeacherChoice.unassign(),
                ),
                icon: const Icon(Icons.person_remove_outlined),
                label: const Text('Unassign'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(
                      dialogContext,
                      _TeacherChoice(
                        teacher: selected,
                        isClassTeacher: classTeacher,
                      ),
                    ),
              child: Text(assignment == null ? 'Assign' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (result.unassign) {
      context.read<TeacherAssignmentBloc>().add(
        DeleteTeacherAssignment(assignment!.id),
      );
      return;
    }
    final teacher = result.teacher!;
    final now = DateTime.now();
    context.read<TeacherAssignmentBloc>().add(
      SaveTeacherAssignment(
        TeacherAssignmentEntity(
          id: assignment?.id ?? sl<TeacherAssignmentRepository>().generateId(),
          teacherId: teacher.id,
          teacherName: teacher.fullName,
          classId: assignment?.classId ?? academicClass.id,
          sectionId: assignment?.sectionId ?? section.id,
          subject: subject.name,
          academicSession: _sessionController.text.trim(),
          isClassTeacher: result.isClassTeacher,
          createdAt: assignment?.createdAt ?? now,
        ),
      ),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _normalise(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}

class _AssignmentOptions {
  const _AssignmentOptions({
    required this.teachers,
    required this.classes,
    required this.sections,
    required this.subjects,
  });

  final List<TeacherEntity> teachers;
  final List<AcademicClassEntity> classes;
  final List<SectionEntity> sections;
  final List<AcademicSubjectEntity> subjects;

  AcademicClassEntity? classById(String? id) =>
      classes.where((item) => item.id == id).firstOrNull;

  SectionEntity? sectionById(String? id) =>
      sections.where((item) => item.id == id).firstOrNull;

  List<SectionEntity> sectionsFor(String? classId) =>
      sections.where((item) => item.classId == classId).toList(growable: false);

  List<AcademicSubjectEntity> subjectsFor(String? classId, String? sectionId) {
    final sectionSubjects = subjects
        .where((item) => item.classId == classId && item.sectionId == sectionId)
        .toList(growable: false);
    if (sectionSubjects.isNotEmpty) return sectionSubjects;
    return subjects
        .where((item) => item.classId == classId && item.sectionId == null)
        .toList(growable: false);
  }
}

class _TeacherChoice {
  const _TeacherChoice({required this.teacher, required this.isClassTeacher})
    : unassign = false;

  const _TeacherChoice.unassign()
    : teacher = null,
      isClassTeacher = false,
      unassign = true;

  final TeacherEntity? teacher;
  final bool isClassTeacher;
  final bool unassign;
}
