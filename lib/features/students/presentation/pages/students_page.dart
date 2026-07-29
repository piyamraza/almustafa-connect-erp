import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'student_details_page.dart';
import '../../../../core/di/service_locator.dart';
import 'add_student_page.dart';
import '../bloc/student_bloc.dart';
import '../bloc/student_event.dart';
import '../bloc/student_state.dart';

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudentBloc>()..add(const LoadStudentsEvent()),
      child: const _StudentsView(),
    );
  }
}

class _StudentsView extends StatefulWidget {
  const _StudentsView();

  @override
  State<_StudentsView> createState() =>
      _StudentsViewState();
}

class _StudentsViewState
    extends State<_StudentsView> {
  final TextEditingController
      _searchController = TextEditingController();

  String _searchQuery = '';

  Future<void> _refreshStudents(BuildContext context) async {
    final studentBloc = context.read<StudentBloc>();

    studentBloc.add(const RefreshStudentsEvent());

    await studentBloc.stream.firstWhere(
      (state) => state is StudentLoaded || state is StudentError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
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
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Student'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
	      controller: _searchController,
onChanged: (value) {
  setState(() {
    _searchQuery = value.trim().toLowerCase();
  });
},
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
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
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is StudentLoaded && state.students.isEmpty) {
                    return _buildScrollableState(
                      context: context,
                      child: const Text('No students found.'),
                    );
                  }

                  if (state is StudentLoaded) {
final filteredStudents = state.students.where((student) {
  if (_searchQuery.isEmpty) return true;

return student.fullName.toLowerCase().contains(_searchQuery) ||
    student.admissionNo.toLowerCase().contains(_searchQuery) ||
    student.fatherName.toLowerCase().contains(_searchQuery) ||
    student.motherName.toLowerCase().contains(_searchQuery) ||
    student.guardianPhone.toLowerCase().contains(_searchQuery) ||
    student.guardianEmail.toLowerCase().contains(_searchQuery) ||
    student.classId.toLowerCase().contains(_searchQuery) ||
    student.sectionId.toLowerCase().contains(_searchQuery);
}).toList();
                    return Card(
                      elevation: 2,
                      child: RefreshIndicator(
                        onRefresh: () => _refreshStudents(context),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredStudents.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];

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
                                '${student.admissionNo} • ${student.classId}-${student.sectionId}',
                              ),
                              trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: student.isActive
            ? Colors.green.shade100
            : Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        student.isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: student.isActive
              ? Colors.green.shade800
              : Colors.red.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    ),
    const SizedBox(width: 8),
    IconButton(
      icon: const Icon(Icons.edit),
      tooltip: 'Edit',
      onPressed: () async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<StudentBloc>(),
        child: AddStudentPage(
          student: student,
        ),
      ),
    ),
  );

  if (result == true && context.mounted) {
    await _refreshStudents(context);
  }
},
    ),
    IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: 'Delete',
      onPressed: () async {
        final shouldDelete =
            await _showDeleteConfirmationDialog();

        if (!shouldDelete || !context.mounted) {
          return;
        }

        context.read<StudentBloc>().add(
          DeleteStudentEvent(student.id),
        );
      },
    ),
  ],
),
                              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => StudentDetailsPage(
        student: student,
      ),
    ),
  );
},
                            );
                          },
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

Future<bool> _showDeleteConfirmationDialog() async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete Student'),
        content: const Text(
          'Are you sure you want to delete this student?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
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
          children: [
            SizedBox(
              height: 320,
              child: Center(child: child),
            ),
          ],
        ),
      ),
    );
  }
}
