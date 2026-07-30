import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/teacher_entity.dart';
import '../bloc/teacher_bloc.dart';
import '../bloc/teacher_event.dart';
import '../bloc/teacher_state.dart';
import 'upsert_teacher_page.dart';
import 'teacher_assignments_page.dart';
import 'teacher_attendance_page.dart';

class TeachersPage extends StatelessWidget {
  const TeachersPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider<TeacherBloc>(
        create: (_) => sl<TeacherBloc>()..add(const LoadTeachersEvent()),
        child: const _TeachersView(),
      );
}

class _TeachersView extends StatefulWidget { const _TeachersView(); @override State<_TeachersView> createState() => _TeachersViewState(); }
class _TeachersViewState extends State<_TeachersView> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _designation;
  bool? _active;
  @override void dispose() { _searchController.dispose(); super.dispose(); }
  List<TeacherEntity> _filter(List<TeacherEntity> teachers) => teachers.where((teacher) {
    final text = [teacher.employeeId, teacher.fullName, teacher.phone, teacher.email, teacher.gender, teacher.address, teacher.designation, teacher.qualification, teacher.specialization, teacher.isActive ? 'active' : 'inactive'].join(' ').toLowerCase();
    return (_search.isEmpty || text.contains(_search)) && (_designation == null || teacher.designation == _designation) && (_active == null || teacher.isActive == _active);
  }).toList();
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Teachers'),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TeacherAssignmentsPage()),
          ),
          icon: const Icon(Icons.assignment_ind_outlined),
          label: const Text('Assignments'),
        ),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TeacherAttendancePage()),
          ),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Attendance'),
        ),
      ],
    ),
    body: Padding(padding: const EdgeInsets.all(16), child: BlocBuilder<TeacherBloc, TeacherState>(builder: (context, state) {
      if (state is TeacherLoading || state is TeacherInitial) return const Center(child: CircularProgressIndicator());
      if (state is TeacherError) return Center(child: Text(state.message));
      final teachers = state is TeacherLoaded ? _filter(state.teachers) : const <TeacherEntity>[];
      final designations = state is TeacherLoaded
          ? (state.teachers
                .map((teacher) => teacher.designation)
                .where((value) => value.isNotEmpty)
                .toSet()
                .toList()
              ..sort())
          : <String>[];
      return Column(children: [
        TextField(controller: _searchController, onChanged: (value) => setState(() => _search = value.trim().toLowerCase()), decoration: InputDecoration(hintText: 'Search by any teacher detail...', prefixIcon: const Icon(Icons.search), suffixIcon: _search.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: _searchController.clear), border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        Stack(alignment: Alignment.center, children: [
          Align(alignment: Alignment.centerLeft, child: SizedBox(width: 190, height: 56, child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BlocProvider.value(value: context.read<TeacherBloc>(), child: const UpsertTeacherPage()))),
            icon: const Icon(Icons.person_add_alt_1), label: const Text('Add Teacher'),
          ))),
          Padding(padding: const EdgeInsets.only(left: 218), child: Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 10, children: [
          SizedBox(width: 190, child: DropdownButtonFormField<String>(value: designations.contains(_designation) ? _designation : null, decoration: const InputDecoration(labelText: 'Designation', border: OutlineInputBorder()), items: [const DropdownMenuItem(value: null, child: Text('All')), ...designations.map((value) => DropdownMenuItem(value: value, child: Text(value)))], onChanged: (value) => setState(() => _designation = value))),
          SizedBox(width: 160, child: DropdownButtonFormField<bool>(value: _active, decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: null, child: Text('All')), DropdownMenuItem(value: true, child: Text('Active')), DropdownMenuItem(value: false, child: Text('Inactive'))], onChanged: (value) => setState(() => _active = value))),
          if (_designation != null || _active != null) TextButton.icon(onPressed: () => setState(() { _designation = null; _active = null; }), icon: const Icon(Icons.filter_alt_off_outlined), label: const Text('Clear filters')),
          ])),
        ]),
        const SizedBox(height: 16),
        Expanded(child: Card(child: teachers.isEmpty ? const Center(child: Text('No teachers found.')) : ListView.separated(itemCount: teachers.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (context, index) { final teacher = teachers[index]; return ListTile(leading: CircleAvatar(child: Text(teacher.firstName.isEmpty ? '?' : teacher.firstName[0].toUpperCase())), title: Text(teacher.fullName), subtitle: Text('${teacher.employeeId} • ${teacher.designation}${teacher.specialization.isEmpty ? '' : ' • ${teacher.specialization}'}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [_TeacherStatus(active: teacher.isActive), IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BlocProvider.value(value: context.read<TeacherBloc>(), child: UpsertTeacherPage(teacher: teacher)))))])); }))),
      ]);
    })),
  );
}

class _TeacherStatus extends StatelessWidget { const _TeacherStatus({required this.active}); final bool active; @override Widget build(BuildContext context) => Chip(label: Text(active ? 'Active' : 'Inactive'), backgroundColor: active ? Colors.green.shade100 : Colors.red.shade100, side: BorderSide.none, labelStyle: TextStyle(color: active ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.w600)); }
