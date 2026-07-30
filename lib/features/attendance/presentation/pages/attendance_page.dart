import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'mark_attendance_page.dart';
import 'attendance_history_page.dart';
import 'student_attendance_page.dart';
import 'attendance_reports_page.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            int crossAxisCount = 1;

if (width >= 1200) {
  crossAxisCount = 4;
} else if (width >= 700) {
  crossAxisCount = 2;
}

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1450),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.0,
                    ),
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return _AttendanceCard(
                            title: 'Mark Attendance',
                            icon: Icons.edit_calendar_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MarkAttendancePage(),
                                ),
                              );
                            },
                          );
                        case 1:
                          return _AttendanceCard(
                            title: 'Attendance History',
                            icon: Icons.history,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AttendanceHistoryPage(),
                                ),
                              );
                            },
                          );
                        case 2:
                          return _AttendanceCard(
                            title: 'Student Attendance',
                            icon: Icons.person_outline,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StudentAttendancePage(),
                                ),
                              );
                            },
                          );
                        case 3:
                          return _AttendanceCard(
                            title: 'Attendance Reports',
                            icon: Icons.bar_chart_outlined,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceReportsPage())),
                          );
                        default:
                          return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDisabled;

  const _AttendanceCard({
    required this.title,
    required this.icon,
    this.onTap,
    this.isDisabled = false,
  });

  @override
  State<_AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<_AttendanceCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardColor = widget.isDisabled
        ? theme.colorScheme.surfaceVariant
        : theme.colorScheme.surface;

    final elevation = _hovering && !widget.isDisabled ? 6.0 : 2.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: elevation * 4,
              offset: Offset(0, elevation),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.isDisabled ? null : widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      if (widget.isDisabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.isDisabled ? null : widget.onTap,
                      child: const Text('Open'),
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
