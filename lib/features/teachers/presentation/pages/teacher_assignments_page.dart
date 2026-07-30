import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
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
      create: (_) => sl<TeacherAssignmentBloc>()
        ..add(const LoadTeacherAssignments()),
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
  final _formKey = GlobalKey<FormState>();
  final _classController = TextEditingController();
  final _sectionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _sessionController = TextEditingController(
    text: '${DateTime.now().year}-${DateTime.now().year + 1}',
  );
  late final Future<List<TeacherEntity>> _teachersFuture;
  TeacherEntity? _selectedTeacher;
  bool _isClassTeacher = false;

  @override
  void initState() {
    super.initState();
    _teachersFuture = sl<TeacherRepository>().getTeachers();
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
              selectedTeacher: _selectedTeacher,
              classController: _classController,
              sectionController: _sectionController,
              subjectController: _subjectController,
              sessionController: _sessionController,
              isClassTeacher: _isClassTeacher,
              onTeacherChanged: (teacher) =>
                  setState(() => _selectedTeacher = teacher),
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
    required this.selectedTeacher,
    required this.classController,
    required this.sectionController,
    required this.subjectController,
    required this.sessionController,
    required this.isClassTeacher,
    required this.onTeacherChanged,
    required this.onClassTeacherChanged,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final Future<List<TeacherEntity>> teachersFuture;
  final TeacherEntity? selectedTeacher;
  final TextEditingController classController;
  final TextEditingController sectionController;
  final TextEditingController subjectController;
  final TextEditingController sessionController;
  final bool isClassTeacher;
  final ValueChanged<TeacherEntity?> onTeacherChanged;
  final ValueChanged<bool> onClassTeacherChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: FutureBuilder<List<TeacherEntity>>(
            future: teachersFuture,
            builder: (context, snapshot) {
              final teachers = snapshot.data ?? const <TeacherEntity>[];
              return Column(
                children: [
                  DropdownButtonFormField<TeacherEntity>(
                    value: selectedTeacher,
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
                          _field(classController, 'Class', width),
                          _field(sectionController, 'Section', width),
                          _field(subjectController, 'Subject', width),
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
        if (state is TeacherAssignmentError) return Center(child: Text(state.message));
        final assignments = state is TeacherAssignmentLoaded
            ? state.assignments
            : const <TeacherAssignmentEntity>[];
        return Card(
          child: assignments.isEmpty
              ? const Center(child: Text('No academic assignments yet.'))
              : ListView.separated(
                  itemCount: assignments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
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
