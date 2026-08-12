import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../../core/widgets/app_page_layout.dart';
import '../../../results/presentation/pages/teacher_results_page.dart';
import '../../../staff/presentation/pages/teacher_leave_page.dart'
    as staff_teacher_leave;
import '../../../timetable/presentation/pages/teacher_workload_page.dart';
import 'teacher_assignments_page.dart';
import 'teacher_reports_page.dart';
import 'teachers_page.dart';

class TeachersModulePage extends StatelessWidget {
  const TeachersModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = <_TeacherAction>[
      _TeacherAction(
        'Teacher Directory',
        'Profiles, contacts and employment records',
        Icons.people_alt_rounded,
        const Color(0xFF246BFD),
        () => _open(context, const TeachersPage()),
      ),
      _TeacherAction(
        'Academic Assignments',
        'Assign classes, sections and subjects',
        Icons.assignment_ind_rounded,
        const Color(0xFF7C3AED),
        () => _open(context, const TeacherAssignmentsPage()),
      ),
      _TeacherAction(
        'Leave Management',
        'Requests, approvals and leave history',
        Icons.event_available_rounded,
        const Color(0xFF0AA47A),
        () => _open(context, const staff_teacher_leave.TeacherLeavePage()),
      ),
      _TeacherAction(
        'Timetable & Workload',
        'Teaching schedule and workload overview',
        Icons.calendar_month_rounded,
        const Color(0xFFF59E0B),
        () => _open(context, const TeacherWorkloadPage()),
      ),
      _TeacherAction(
        'Teacher Results',
        'Result entry and academic performance',
        Icons.fact_check_rounded,
        const Color(0xFFEC4899),
        () => _open(context, const TeacherResultsPage()),
      ),
      _TeacherAction(
        'Teacher Reports',
        'Attendance and workforce insights',
        Icons.analytics_rounded,
        const Color(0xFF06A7C6),
        () => _open(context, const TeacherReportsPage()),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        actions: const [DashboardNavigationButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1150
              ? 3
              : constraints.maxWidth >= 700
              ? 2
              : 2;
          return SingleChildScrollView(
            padding: EdgeInsets.all(constraints.maxWidth < 700 ? 10 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1450),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TeacherHero(),
                    const SizedBox(height: 22),
                    const Text(
                      'Teacher Operations',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14213D),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Manage the complete teacher journey from one place.',
                      style: TextStyle(color: Colors.blueGrey.shade600),
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: actions.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        mainAxisExtent: constraints.maxWidth < 700 ? 126 : 150,
                      ),
                      itemBuilder: (_, i) => _TeacherCard(action: actions[i]),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class _TeacherHero extends StatelessWidget {
  const _TeacherHero();
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 600) {
      return const AppModuleHero(
        title: 'Teacher Management Center',
        description: 'Manage the complete teacher journey.',
        icon: Icons.school_rounded,
        decorativeIcon: Icons.menu_book_rounded,
        colors: [Color(0xFF2878FF), Color(0xFF1646A8)],
      );
    }
    return Container(
      height: 138,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF276EF1), Color(0xFF123F9C)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30276EF1),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher Management Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Build a connected, organised and high-performing academic team.',
                  style: TextStyle(color: Color(0xFFE8F1FF), fontSize: 15),
                ),
              ],
            ),
          ),
          Icon(
            Icons.auto_stories_rounded,
            size: 94,
            color: Colors.white.withValues(alpha: .08),
          ),
        ],
      ),
    );
  }
}

class _TeacherAction {
  const _TeacherAction(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  );
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _TeacherCard extends StatelessWidget {
  const _TeacherCard({required this.action});
  final _TeacherAction action;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: action.color.withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(
            color: action.color.withValues(alpha: .08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: action.onTap,
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 18),
            child: compact
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: action.color.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(action.icon, color: action.color, size: 21),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        action.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF14213D),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: action.color.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(action.icon, color: action.color, size: 29),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF14213D),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              action.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: action.color),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
