import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/teacher_entity.dart';
import '../bloc/teacher_bloc.dart';
import '../bloc/teacher_event.dart';
import '../bloc/teacher_state.dart';
import 'upsert_teacher_page.dart';
import 'teacher_assignments_page.dart';
import '../../../employee_hr/presentation/pages/teacher_appointment_letters_page.dart';

class TeachersPage extends StatelessWidget {
  const TeachersPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider<TeacherBloc>(
    create: (_) => sl<TeacherBloc>()..add(const LoadTeachersEvent()),
    child: const _TeachersView(),
  );
}

class _TeachersView extends StatefulWidget {
  const _TeachersView();
  @override
  State<_TeachersView> createState() => _TeachersViewState();
}

class _TeachersViewState extends State<_TeachersView> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _designation;
  bool? _active;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TeacherEntity> _filter(List<TeacherEntity> teachers) =>
      teachers.where((teacher) {
        final text = [
          teacher.employeeId,
          teacher.fullName,
          teacher.phone,
          teacher.email,
          teacher.gender,
          teacher.address,
          teacher.designation,
          teacher.qualification,
          teacher.specialization,
          teacher.isActive ? 'active' : 'inactive',
        ].join(' ').toLowerCase();
        return (_search.isEmpty || text.contains(_search)) &&
            (_designation == null || teacher.designation == _designation) &&
            (_active == null || teacher.isActive == _active);
      }).toList();
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        actions: [
          const DashboardNavigationButton(),
          if (isMobile)
            IconButton(
              tooltip: 'Assignments',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TeacherAssignmentsPage(),
                ),
              ),
              icon: const Icon(Icons.assignment_ind_outlined),
            )
          else
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TeacherAssignmentsPage(),
                ),
              ),
              icon: const Icon(Icons.assignment_ind_outlined),
              label: const Text('Assignments'),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 10 : 16),
        child: BlocBuilder<TeacherBloc, TeacherState>(
          builder: (context, state) {
            if (state is TeacherLoading || state is TeacherInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TeacherError) {
              return Center(child: Text(state.message));
            }
            final teachers = state is TeacherLoaded
                ? _filter(state.teachers)
                : const <TeacherEntity>[];
            final designations = state is TeacherLoaded
                ? (state.teachers
                      .map((teacher) => teacher.designation)
                      .where((value) => value.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort())
                : <String>[];
            return Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _search = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by any teacher detail...',
                    isDense: isMobile,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _searchController.clear,
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                SizedBox(
                  height: isMobile ? 48 : 56,
                  child: Row(
                    children: [
                      SizedBox(
                        width: isMobile ? 92 : 190,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<TeacherBloc>(),
                                child: const UpsertTeacherPage(),
                              ),
                            ),
                          ),
                          icon: Icon(
                            Icons.person_add_alt_1,
                            size: isMobile ? 18 : 24,
                          ),
                          label: Text(isMobile ? 'Add' : 'Add Teacher'),
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      Expanded(
                        flex: 6,
                        child: DropdownButtonFormField<String>(
                          initialValue: designations.contains(_designation)
                              ? _designation
                              : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Designation',
                            border: const OutlineInputBorder(),
                            isDense: isMobile,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 9 : 12,
                              vertical: isMobile ? 9 : 16,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All'),
                            ),
                            ...designations.map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _designation = value),
                        ),
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<bool>(
                          initialValue: _active,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: const OutlineInputBorder(),
                            isDense: isMobile,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 9 : 12,
                              vertical: isMobile ? 9 : 16,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All')),
                            DropdownMenuItem(
                              value: true,
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: false,
                              child: Text('Inactive'),
                            ),
                          ],
                          onChanged: (value) => setState(() => _active = value),
                        ),
                      ),
                      if (!isMobile &&
                          (_designation != null || _active != null))
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _designation = null;
                            _active = null;
                          }),
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Clear filters'),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 16),
                Expanded(
                  child: Card(
                    child: teachers.isEmpty
                        ? const Center(child: Text('No teachers found.'))
                        : ListView.separated(
                            itemCount: teachers.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final teacher = teachers[index];
                              return ListTile(
                                dense: isMobile,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 10 : 16,
                                  vertical: isMobile ? 2 : 4,
                                ),
                                leading: CircleAvatar(
                                  radius: isMobile ? 20 : null,
                                  child: Text(
                                    teacher.firstName.isEmpty
                                        ? '?'
                                        : teacher.firstName[0].toUpperCase(),
                                  ),
                                ),
                                title: Text(teacher.fullName),
                                subtitle: Text(
                                  '${teacher.employeeId} • ${teacher.designation}${teacher.specialization.isEmpty ? '' : ' • ${teacher.specialization}'}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _TeacherStatus(active: teacher.isActive),
                                    IconButton(
                                      tooltip: 'Generate Appointment Letter',
                                      visualDensity: isMobile
                                          ? VisualDensity.compact
                                          : null,
                                      icon: Icon(
                                        Icons.assignment_turned_in_outlined,
                                        size: isMobile ? 20 : 24,
                                      ),
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => TeacherAppointmentLettersPage(
                                            initialTeacher: teacher,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: isMobile
                                          ? VisualDensity.compact
                                          : null,
                                      icon: Icon(
                                        Icons.edit,
                                        size: isMobile ? 20 : 24,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  BlocProvider.value(
                                                    value: context
                                                        .read<TeacherBloc>(),
                                                    child: UpsertTeacherPage(
                                                      teacher: teacher,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TeacherStatus extends StatelessWidget {
  const _TeacherStatus({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Chip(
    visualDensity: VisualDensity.compact,
    label: Text(active ? 'Active' : 'Inactive'),
    backgroundColor: active ? Colors.green.shade100 : Colors.red.shade100,
    side: BorderSide.none,
    labelStyle: TextStyle(
      color: active ? Colors.green.shade800 : Colors.red.shade800,
      fontWeight: FontWeight.w600,
    ),
  );
}
