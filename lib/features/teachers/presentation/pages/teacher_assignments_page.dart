import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/teacher_assignment_entity.dart';
import '../../domain/entities/teacher_entity.dart';
import '../../domain/repositories/teacher_assignment_repository.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../bloc/teacher_assignment_bloc.dart';

class TeacherAssignmentsPage extends StatelessWidget {
  const TeacherAssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeacherAssignmentBloc>(
      create: (_) => sl<TeacherAssignmentBloc>()
        ..add(const LoadTeacherAssignments()),
      child: BlocListener<TeacherAssignmentBloc, TeacherAssignmentState>(
        listenWhen: (_, current) => current is TeacherAssignmentError,
        listener: (context, state) {
          if (state is TeacherAssignmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: const _AssignmentsView(),
      ),
    );
  }
}

class _AssignmentsView extends StatefulWidget {
  const _AssignmentsView();

  @override
  State<_AssignmentsView> createState() => _AssignmentsViewState();
}

class _AssignmentsViewState extends State<_AssignmentsView> {
  final _formKey = GlobalKey<FormState>();
  final _classController = TextEditingController();
  final _sectionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _sessionController = TextEditingController(
    text: '${DateTime.now().year}-${DateTime.now().year + 1}',
  );
  late final Future<List<TeacherEntity>> _teachersFuture;
  late final Future<List<AcademicClassEntity>> _classesFuture;
  late final Future<List<SectionEntity>> _sectionsFuture;
  late final Future<List<AcademicSubjectEntity>> _subjectsFuture;
  TeacherEntity? _selectedTeacher;
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedSubject;
  bool _isClassTeacher = false;

  @override
  void initState() {
    super.initState();
    _teachersFuture = sl<TeacherRepository>().getTeachers();
    final structureRepository = sl<AcademicStructureRepository>();
    _classesFuture = structureRepository.getClasses();
    _sectionsFuture = structureRepository.getSections();
    _subjectsFuture = structureRepository.getSubjects();
  }

  @override
  void dispose() {
    _classController.dispose();
    _sectionController.dispose();
    _subjectController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  void _saveAssignment() {
    if (!_formKey.currentState!.validate() || _selectedTeacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a teacher and complete required fields.')),
      );
      return;
    }
    final repository = sl<TeacherAssignmentRepository>();
    context.read<TeacherAssignmentBloc>().add(
      SaveTeacherAssignment(
        TeacherAssignmentEntity(
          id: repository.generateId(),
          teacherId: _selectedTeacher!.id,
          teacherName: _selectedTeacher!.fullName,
          classId: _classController.text.trim(),
          sectionId: _sectionController.text.trim(),
          subject: _subjectController.text.trim(),
          academicSession: _sessionController.text.trim(),
          isClassTeacher: _isClassTeacher,
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academic Assignments')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _AssignmentForm(
              formKey: _formKey,
              teachersFuture: _teachersFuture,
              classesFuture: _classesFuture,
              sectionsFuture: _sectionsFuture,
              subjectsFuture: _subjectsFuture,
              selectedTeacher: _selectedTeacher,
              selectedClass: _selectedClass,
              selectedSection: _selectedSection,
              selectedSubject: _selectedSubject,
              classController: _classController,
              sectionController: _sectionController,
              subjectController: _subjectController,
              sessionController: _sessionController,
              isClassTeacher: _isClassTeacher,
              onTeacherChanged: (teacher) =>
                  setState(() => _selectedTeacher = teacher),
              onClassChanged: (value) => setState(() {
                _selectedClass = value;
                _selectedSection = null;
                _selectedSubject = null;
                _classController.text = value ?? '';
                _sectionController.clear();
                _subjectController.clear();
              }),
              onSectionChanged: (value) => setState(() {
                _selectedSection = value;
                _selectedSubject = null;
                _sectionController.text = value ?? '';
                _subjectController.clear();
              }),
              onSubjectChanged: (value) => setState(() {
                _selectedSubject = value;
                _subjectController.text = value ?? '';
              }),
              onClassTeacherChanged: (value) =>
                  setState(() => _isClassTeacher = value),
              onSave: _saveAssignment,
            ),
            const SizedBox(height: 16),
            const Expanded(child: _AssignmentsList()),
          ],
        ),
      ),
    );
  }
}

class _AssignmentForm extends StatelessWidget {
  const _AssignmentForm({
    required this.formKey,
    required this.teachersFuture,
    required this.classesFuture,
    required this.sectionsFuture,
    required this.subjectsFuture,
    required this.selectedTeacher,
    required this.selectedClass,
    required this.selectedSection,
    required this.selectedSubject,
    required this.classController,
    required this.sectionController,
    required this.subjectController,
    required this.sessionController,
    required this.isClassTeacher,
    required this.onTeacherChanged,
    required this.onClassChanged,
    required this.onSectionChanged,
    required this.onSubjectChanged,
    required this.onClassTeacherChanged,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final Future<List<TeacherEntity>> teachersFuture;
  final Future<List<AcademicClassEntity>> classesFuture;
  final Future<List<SectionEntity>> sectionsFuture;
  final Future<List<AcademicSubjectEntity>> subjectsFuture;
  final TeacherEntity? selectedTeacher;
  final String? selectedClass;
  final String? selectedSection;
  final String? selectedSubject;
  final TextEditingController classController;
  final TextEditingController sectionController;
  final TextEditingController subjectController;
  final TextEditingController sessionController;
  final bool isClassTeacher;
  final ValueChanged<TeacherEntity?> onTeacherChanged;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<bool> onClassTeacherChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: FutureBuilder<List<Object>>(
            future: Future.wait<Object>([
              teachersFuture,
              classesFuture,
              sectionsFuture,
              subjectsFuture,
            ]),
            builder: (context, snapshot) {
              final values = snapshot.data;
              final teachers = values == null
                  ? const <TeacherEntity>[]
                  : values[0] as List<TeacherEntity>;
              final classes = values == null
                  ? const <AcademicClassEntity>[]
                  : values[1] as List<AcademicClassEntity>;
              final allSections = values == null
                  ? const <SectionEntity>[]
                  : values[2] as List<SectionEntity>;
              final allSubjects = values == null
                  ? const <AcademicSubjectEntity>[]
                  : values[3] as List<AcademicSubjectEntity>;
              AcademicClassEntity? selectedClassEntity;
              for (final academicClass in classes) {
                if (academicClass.name == selectedClass) {
                  selectedClassEntity = academicClass;
                  break;
                }
              }
              final classNames = classes
                  .where((value) => value.isActive)
                  .map((value) => value.name)
                  .toList()
                ..sort();
              final sections = <String>[
                if (selectedClassEntity != null)
                  ...allSections
                      .where(
                        (value) =>
                            value.isActive &&
                            value.classId == selectedClassEntity!.id,
                      )
                      .map((value) => value.name),
              ]..sort();
              SectionEntity? selectedSectionEntity;
              for (final section in allSections) {
                if (section.classId == selectedClassEntity?.id &&
                    section.name == selectedSection) {
                  selectedSectionEntity = section;
                  break;
                }
              }
              final sectionSubjects = <AcademicSubjectEntity>[
                if (selectedClassEntity != null && selectedSectionEntity != null)
                  ...allSubjects.where(
                    (value) =>
                        value.isActive &&
                        value.classId == selectedClassEntity!.id &&
                        value.sectionId == selectedSectionEntity!.id,
                  ),
              ];
              final subjects = <String>[
                ...(sectionSubjects.isNotEmpty
                    ? sectionSubjects
                    : allSubjects.where(
                        (value) =>
                            value.isActive &&
                            value.classId == selectedClassEntity?.id &&
                            value.sectionId == null,
                      ))
                    .map((value) => value.name),
              ]..sort();
              return Column(
                children: [
                  DropdownButtonFormField<TeacherEntity>(
                    initialValue: selectedTeacher,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Teacher',
                      border: OutlineInputBorder(),
                    ),
                    items: teachers
                        .map(
                          (teacher) => DropdownMenuItem<TeacherEntity>(
                            value: teacher,
                            child: Text(
                              '${teacher.fullName} (${teacher.employeeId})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onTeacherChanged,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth >= 700
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _dropdown(
                            label: 'Class',
                            width: width,
                            value: selectedClass,
                            items: classNames,
                            onChanged: onClassChanged,
                          ),
                          _dropdown(
                            label: 'Section',
                            width: width,
                            value: selectedSection,
                            items: sections,
                            onChanged: onSectionChanged,
                            enabled: selectedClass != null,
                          ),
                          _dropdown(
                            label: 'Subject',
                            width: width,
                            value: selectedSubject,
                            items: subjects,
                            onChanged: onSubjectChanged,
                            enabled: selectedSection != null,
                          ),
                          _field(sessionController, 'Academic session', width),
                        ],
                      );
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Assign as class teacher'),
                    value: isClassTeacher,
                    onChanged: onClassTeacherChanged,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.add),
                      label: const Text('Save Assignment'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, double width) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        validator: (value) => value == null || value.trim().isEmpty
            ? '$label is required'
            : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required double width,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: enabled ? onChanged : null,
        validator: (value) => value == null ? '$label is required' : null,
      ),
    );
  }
}

class _AssignmentsList extends StatelessWidget {
  const _AssignmentsList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeacherAssignmentBloc, TeacherAssignmentState>(
      builder: (context, state) {
        if (state is TeacherAssignmentLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TeacherAssignmentError && state.assignments.isEmpty) {
          return Center(child: Text(state.message));
        }
        final assignments = state is TeacherAssignmentLoaded
            ? state.assignments
            : state is TeacherAssignmentError
            ? state.assignments
            : const <TeacherAssignmentEntity>[];
        return Card(
          child: assignments.isEmpty
              ? const Center(child: Text('No academic assignments yet.'))
              : ListView.separated(
                  itemCount: assignments.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    return ListTile(
                      title: Text(assignment.teacherName),
                      subtitle: Text(
                        '${assignment.subject} • ${assignment.classId}-${assignment.sectionId} '
                        '• ${assignment.academicSession}'
                        '${assignment.isClassTeacher ? ' • Class Teacher' : ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => context
                            .read<TeacherAssignmentBloc>()
                            .add(DeleteTeacherAssignment(assignment.id)),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
