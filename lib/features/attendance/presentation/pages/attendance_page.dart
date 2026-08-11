import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../staff/presentation/pages/staff_attendance_history_page.dart';
import '../../../staff/presentation/pages/staff_attendance_page.dart';
import '../../../teachers/presentation/pages/teacher_attendance_history_page.dart';
import '../../../teachers/presentation/pages/teacher_attendance_page.dart';
import 'attendance_history_page.dart';
import 'attendance_reports_page.dart';
import 'mark_attendance_page.dart';
import 'student_attendance_page.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final markingActions = <_AttendanceAction>[
      _AttendanceAction(
        title: 'Student Attendance',
        description: 'Mark daily class attendance quickly and accurately.',
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF1769E8),
        label: 'Mark Students',
        page: const MarkAttendancePage(),
      ),
      _AttendanceAction(
        title: 'Teacher Attendance',
        description: 'Record teacher presence, leave and late arrival.',
        icon: Icons.co_present_rounded,
        color: const Color(0xFF7C3AED),
        label: 'Mark Teachers',
        page: const TeacherAttendancePage(),
      ),
      _AttendanceAction(
        title: 'Staff Attendance',
        description: 'Manage daily attendance for all non-teaching staff.',
        icon: Icons.badge_rounded,
        color: const Color(0xFF0F9D74),
        label: 'Mark Staff',
        page: const StaffAttendancePage(),
      ),
    ];
    final insightActions = <_AttendanceAction>[
      _AttendanceAction(
        title: 'Student History',
        description: 'Review previously marked class attendance.',
        icon: Icons.history_edu_rounded,
        color: const Color(0xFF0EA5E9),
        label: 'Open History',
        page: const AttendanceHistoryPage(),
      ),
      _AttendanceAction(
        title: 'Teacher History',
        description: 'View individual teacher attendance records.',
        icon: Icons.manage_history_rounded,
        color: const Color(0xFF8B5CF6),
        label: 'Open History',
        page: const TeacherAttendanceHistoryPage(),
      ),
      _AttendanceAction(
        title: 'Staff History',
        description: 'Track attendance history of staff members.',
        icon: Icons.event_note_rounded,
        color: const Color(0xFFF59E0B),
        label: 'Open History',
        page: const StaffAttendanceHistoryPage(),
      ),
      _AttendanceAction(
        title: 'Student Records',
        description: 'Find and inspect one student’s attendance.',
        icon: Icons.person_search_rounded,
        color: const Color(0xFFEC4899),
        label: 'Find Student',
        page: const StudentAttendancePage(),
      ),
      _AttendanceAction(
        title: 'Reports & Analytics',
        description: 'Explore trends, summaries and printable reports.',
        icon: Icons.insights_rounded,
        color: const Color(0xFFEF4444),
        label: 'View Reports',
        page: const AttendanceReportsPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: const [DashboardNavigationButton()],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AttendanceHero(),
                  const SizedBox(height: 12),
                  const _SectionTitle(
                    title: 'Mark Attendance',
                    subtitle: 'Choose the people you want to mark today',
                  ),
                  const SizedBox(height: 7),
                  _ActionGrid(actions: markingActions, featured: true),
                  const SizedBox(height: 12),
                  const _SectionTitle(
                    title: 'History & Insights',
                    subtitle: 'Review records, trends and attendance reports',
                  ),
                  const SizedBox(height: 7),
                  _ActionGrid(actions: insightActions),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceHero extends StatelessWidget {
  const _AttendanceHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 98),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1769E8), Color(0xFF0B3F91)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1769E8).withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(right: 12, top: -42, child: _HeroOrb(size: 100)),
          const Positioned(right: 110, bottom: -55, child: _HeroOrb(size: 78)),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.how_to_reg_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Command Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mark attendance, monitor daily records and understand trends from one place.',
                      style: TextStyle(color: Color(0xFFDCEAFF), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.07),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      const SizedBox(height: 1),
      Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
      ),
    ],
  );
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions, this.featured = false});
  final List<_AttendanceAction> actions;
  final bool featured;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 620
          ? 1
          : constraints.maxWidth < 1000
          ? 2
          : featured
          ? 3
          : 5;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: featured ? 150 : 138,
        ),
        itemBuilder: (context, index) =>
            _ActionCard(action: actions[index], featured: featured),
      );
    },
  );
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({required this.action, required this.featured});
  final _AttendanceAction action;
  final bool featured;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              action.color.withValues(alpha: 0.12),
              Colors.white,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: action.color.withValues(alpha: _hovered ? 0.42 : 0.20),
          ),
          boxShadow: [
            BoxShadow(
              color: action.color.withValues(alpha: _hovered ? 0.16 : 0.07),
              blurRadius: _hovered ? 24 : 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => action.page)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: widget.featured ? 39 : 35,
                        height: widget.featured ? 39 : 35,
                        decoration: BoxDecoration(
                          color: action.color,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: action.color.withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          action.icon,
                          color: Colors.white,
                          size: widget.featured ? 21 : 18,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_outward_rounded, color: action.color),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF17213A),
                      fontSize: widget.featured ? 15.5 : 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      height: 1.15,
                      fontSize: 11.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    action.label,
                    style: TextStyle(
                      color: action.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceAction {
  const _AttendanceAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.label,
    required this.page,
  });
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String label;
  final Widget page;
}
