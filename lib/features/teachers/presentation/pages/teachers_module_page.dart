import 'package:flutter/material.dart';

import 'teacher_assignments_page.dart';
import 'teacher_attendance_page.dart';
import 'teachers_page.dart';
import 'teacher_leave_page.dart';

class TeachersModulePage extends StatelessWidget {
  const TeachersModulePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1200 ? 4 : constraints.maxWidth >= 700 ? 2 : 1;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1450),
                child: GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _TeacherModuleCard(title: 'Teacher Directory', icon: Icons.groups_outlined, onTap: () => _open(context, const TeachersPage())),
                    _TeacherModuleCard(title: 'Academic Assignments', icon: Icons.assignment_ind_outlined, onTap: () => _open(context, const TeacherAssignmentsPage())),
                    _TeacherModuleCard(title: 'Teacher Attendance', icon: Icons.fact_check_outlined, onTap: () => _open(context, const TeacherAttendancePage())),
                    _TeacherModuleCard(title: 'Leave Management', icon: Icons.event_available_outlined, onTap: () => _open(context, const TeacherLeavePage())),
                    const _TeacherModuleCard(title: 'Timetable & Workload', icon: Icons.schedule_outlined),
                    const _TeacherModuleCard(title: 'Teacher Results', icon: Icons.school_outlined),
                    const _TeacherModuleCard(title: 'Teacher Reports', icon: Icons.assessment_outlined),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  static void _open(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class _TeacherModuleCard extends StatelessWidget {
  const _TeacherModuleCard({required this.title, required this.icon, this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
        const Spacer(),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: onTap, child: Text(onTap == null ? 'Coming Soon' : 'Open'))),
      ]),
    ),
  );
}
