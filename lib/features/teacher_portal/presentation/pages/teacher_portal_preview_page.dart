import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import 'teacher_portal_dashboard_page.dart';

class TeacherPortalPreviewPage extends StatefulWidget {
  const TeacherPortalPreviewPage({super.key});

  @override
  State<TeacherPortalPreviewPage> createState() =>
      _TeacherPortalPreviewPageState();
}

class _TeacherPortalPreviewPageState extends State<TeacherPortalPreviewPage> {
  late Future<List<TeacherEntity>> _teachers = _load();

  Future<List<TeacherEntity>> _load() async {
    final values =
        (await sl<TeacherRepository>().getTeachers())
            .where((teacher) => teacher.isActive)
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
    return values;
  }

  void _open(TeacherEntity teacher) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherPortalDashboardPage(
          teacherId: teacher.id,
          previewMode: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Teacher Portal Preview'),
      actions: const [DashboardNavigationButton()],
    ),
    body: FutureBuilder<List<TeacherEntity>>(
      future: _teachers,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Teachers could not be loaded: ${snapshot.error}'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => setState(() => _teachers = _load()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final teachers = snapshot.data ?? const <TeacherEntity>[];
        if (teachers.isEmpty) {
          return const Center(child: Text('No active teachers found.'));
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Select a teacher to inspect the dashboard exactly as that teacher will see it.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                for (final teacher in teachers)
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(teacher.fullName),
                      subtitle: Text(
                        [
                          teacher.employeeId,
                          teacher.designation,
                          teacher.specialization,
                        ].where((value) => value.trim().isNotEmpty).join(' • '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(teacher),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
