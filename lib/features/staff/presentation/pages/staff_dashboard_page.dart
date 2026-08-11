import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../../core/widgets/app_page_layout.dart';

class StaffDashboardPage extends StatelessWidget {
  const StaffDashboardPage({
    required this.onViewStaff,
    required this.onAddStaff,
    required this.onAttendance,
    required this.onSalary,
    required this.onLeave,
    super.key,
  });

  final VoidCallback onViewStaff;
  final VoidCallback onAddStaff;
  final VoidCallback onAttendance;
  final VoidCallback onSalary;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final actions = <_StaffAction>[
      _StaffAction(
        'Staff Directory',
        'View and manage all employee records',
        Icons.groups_rounded,
        const Color(0xFF246BFD),
        onViewStaff,
      ),
      _StaffAction(
        'Add Staff',
        'Register a new team member',
        Icons.person_add_alt_1_rounded,
        const Color(0xFF06A7C6),
        onAddStaff,
      ),
      _StaffAction(
        'Attendance',
        'Mark and monitor daily attendance',
        Icons.fact_check_rounded,
        const Color(0xFF0AA47A),
        onAttendance,
      ),
      _StaffAction(
        'Salary Management',
        'Generate payroll and payment history',
        Icons.payments_rounded,
        const Color(0xFFF59E0B),
        onSalary,
      ),
      _StaffAction(
        'Leave Management',
        'Requests, approvals and leave records',
        Icons.event_available_rounded,
        const Color(0xFFEC4899),
        onLeave,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: const [DashboardNavigationButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1180
              ? 5
              : constraints.maxWidth >= 760
              ? 3
              : constraints.maxWidth >= 520
              ? 2
              : 1;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StaffHero(),
                    const SizedBox(height: 22),
                    const Text(
                      'Staff Operations',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14213D),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Fast access to everyday workforce operations.',
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
                        mainAxisExtent: constraints.maxWidth < 520 ? 124 : 190,
                      ),
                      itemBuilder: (_, i) => _StaffCard(action: actions[i]),
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
}

class _StaffHero extends StatelessWidget {
  const _StaffHero();
  @override
  Widget build(BuildContext context) => const AppModuleHero(
    title: 'Staff Operations Center',
    description: 'Employee records, attendance, payroll and leave.',
    icon: Icons.badge_rounded,
    decorativeIcon: Icons.diversity_3_rounded,
    colors: [Color(0xFF0BA781), Color(0xFF075B73)],
  );
}

class _StaffAction {
  const _StaffAction(
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

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.action});
  final _StaffAction action;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: action.color.withValues(alpha: .2)),
      boxShadow: [
        BoxShadow(
          color: action.color.withValues(alpha: .09),
          blurRadius: 17,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(action.icon, color: action.color, size: 27),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_outward_rounded, color: action.color),
                ],
              ),
              const Spacer(),
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
                style: TextStyle(color: Colors.blueGrey.shade600, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
