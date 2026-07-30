import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/student_entity.dart';
import '../bloc/student_bloc.dart';
import '../bloc/student_event.dart';
import '../bloc/student_state.dart';
import 'add_student_page.dart';
import 'student_details_page.dart';

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StudentBloc>(
      create: (_) => sl<StudentBloc>()..add(const LoadStudentsEvent()),
      child: const _StudentsView(),
    );
  }
}

class _StudentsView extends StatefulWidget {
  const _StudentsView();

  @override
  State<_StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<_StudentsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedClass;
  String? _selectedSection;
  String? _selectedGender;
  bool? _selectedActiveStatus;

  bool get _hasActiveFilters =>
      _selectedClass != null ||
      _selectedSection != null ||
      _selectedGender != null ||
      _selectedActiveStatus != null;

  Future<void> _refreshStudents(BuildContext context) async {
    final bloc = context.read<StudentBloc>();
    bloc.add(const RefreshStudentsEvent());
    await bloc.stream.firstWhere(
      (state) => state is StudentLoaded || state is StudentError,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedClass = null;
      _selectedSection = null;
      _selectedGender = null;
      _selectedActiveStatus = null;
    });
  }

  List<StudentEntity> _filterStudents(List<StudentEntity> students) {
    return students.where((student) {
      final searchableText = [
        student.id,
        student.rollNumber,
        student.admissionNo,
        student.firstName,
        student.lastName,
        student.fullName,
        student.gender,
        student.dateOfBirth.toIso8601String(),
        student.classId,
        student.sectionId,
        student.fatherName,
        student.motherName,
        student.guardianPhone,
        student.guardianEmail,
        student.address,
        student.profileImageUrl,
        student.isActive ? 'active' : 'inactive',
      ].join(' ').toLowerCase();

      return (_searchQuery.isEmpty || searchableText.contains(_searchQuery)) &&
          (_selectedClass == null || student.classId == _selectedClass) &&
          (_selectedSection == null || student.sectionId == _selectedSection) &&
          (_selectedGender == null || student.gender == _selectedGender) &&
          (_selectedActiveStatus == null ||
              student.isActive == _selectedActiveStatus);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search any student detail...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear search',
                        onPressed: _searchController.clear,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<StudentBloc, StudentState>(
                builder: (context, state) {
                  if (state is StudentLoading || state is StudentInitial) {
                    return _buildScrollableState(
                      context: context,
                      child: const CircularProgressIndicator(),
                    );
                  }
                  if (state is StudentError) {
                    return _buildScrollableState(
                      context: context,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          Text(state.message, textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }
                  if (state is! StudentLoaded || state.students.isEmpty) {
                    return _buildScrollableState(
                      context: context,
                      child: const Text('No students found.'),
                    );
                  }

                  final filteredStudents = _filterStudents(state.students);
                  return Column(
                    children: [
                      _StudentFilters(
                        students: state.students,
                        selectedClass: _selectedClass,
                        selectedSection: _selectedSection,
                        selectedGender: _selectedGender,
                        selectedActiveStatus: _selectedActiveStatus,
                        hasActiveFilters: _hasActiveFilters,
                        onClassChanged: (value) =>
                            setState(() => _selectedClass = value),
                        onSectionChanged: (value) =>
                            setState(() => _selectedSection = value),
                        onGenderChanged: (value) =>
                            setState(() => _selectedGender = value),
                        onActiveStatusChanged: (value) =>
                            setState(() => _selectedActiveStatus = value),
                        onClear: _clearFilters,
                        onAddStudent: () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<StudentBloc>(),
                                child: const AddStudentPage(),
                              ),
                            ),
                          );
                          if (result == true && context.mounted) {
                            await _refreshStudents(context);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          elevation: 2,
                          child: RefreshIndicator(
                            onRefresh: () => _refreshStudents(context),
                            child: filteredStudents.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      SizedBox(
                                        height: 320,
                                        child: Center(
                                          child: Text(
                                            'No students match the selected filters.',
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: filteredStudents.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final student = filteredStudents[index];
                                      return _StudentListTile(
                                        student: student,
                                        onRefresh: () =>
                                            _refreshStudents(context),
                                        onDelete: () => _deleteStudent(
                                          context,
                                          student.id,
                                        ),
                                      );
                                    },
                                  ),
                          ),
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
    );
  }

  Future<void> _deleteStudent(BuildContext context, String studentId) async {
    final shouldDelete = await _showDeleteConfirmationDialog();
    if (!shouldDelete || !context.mounted) return;
    context.read<StudentBloc>().add(DeleteStudentEvent(studentId));
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildScrollableState({
    required BuildContext context,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: RefreshIndicator(
        onRefresh: () => _refreshStudents(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: 320, child: Center(child: child))],
        ),
      ),
    );
  }
}

class _StudentFilters extends StatelessWidget {
  const _StudentFilters({
    required this.students,
    required this.selectedClass,
    required this.selectedSection,
    required this.selectedGender,
    required this.selectedActiveStatus,
    required this.hasActiveFilters,
    required this.onClassChanged,
    required this.onSectionChanged,
    required this.onGenderChanged,
    required this.onActiveStatusChanged,
    required this.onClear,
    required this.onAddStudent,
  });

  final List<StudentEntity> students;
  final String? selectedClass;
  final String? selectedSection;
  final String? selectedGender;
  final bool? selectedActiveStatus;
  final bool hasActiveFilters;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<bool?> onActiveStatusChanged;
  final VoidCallback onClear;
  final VoidCallback onAddStudent;

  @override
  Widget build(BuildContext context) {
    final classes = _values(students.map((student) => student.classId));
    final sections = _values(students.map((student) => student.sectionId));
    final genders = _values(students.map((student) => student.gender));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 190,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: onAddStudent,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add Student'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 218),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
            _StringFilter(
              label: 'Class',
              value: selectedClass,
              values: classes,
              onChanged: onClassChanged,
            ),
            _StringFilter(
              label: 'Section',
              value: selectedSection,
              values: sections,
              onChanged: onSectionChanged,
            ),
            _StringFilter(
              label: 'Gender',
              value: selectedGender,
              values: genders,
              onChanged: onGenderChanged,
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<bool>(
                value: selectedActiveStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<bool>(value: null, child: Text('All')),
                  DropdownMenuItem<bool>(value: true, child: Text('Active')),
                  DropdownMenuItem<bool>(
                    value: false,
                    child: Text('Inactive'),
                  ),
                ],
                onChanged: onActiveStatusChanged,
              ),
            ),
            if (hasActiveFilters)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear filters'),
              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<String> _values(Iterable<String> values) {
    final items = values.where((value) => value.trim().isNotEmpty).toSet().toList()
      ..sort();
    return items;
  }
}

class _StringFilter extends StatelessWidget {
  const _StringFilter({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<String>(
        value: values.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('All')),
          ...values.map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _StudentListTile extends StatelessWidget {
  const _StudentListTile({
    required this.student,
    required this.onRefresh,
    required this.onDelete,
  });

  final StudentEntity student;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          student.firstName.isNotEmpty
              ? student.firstName[0].toUpperCase()
              : '?',
        ),
      ),
      title: Text(student.fullName),
      subtitle: Text(
        'Roll: ${student.rollNumber.isEmpty ? '-' : student.rollNumber} • '
        '${student.admissionNo} • ${student.classId}-${student.sectionId}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusChip(active: student.isActive),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<StudentBloc>(),
                    child: AddStudentPage(student: student),
                  ),
                ),
              );
              if (result == true && context.mounted) await onRefresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => StudentDetailsPage(student: student)),
        );
        if (result == true && context.mounted) await onRefresh();
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: active ? Colors.green.shade800 : Colors.red.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
