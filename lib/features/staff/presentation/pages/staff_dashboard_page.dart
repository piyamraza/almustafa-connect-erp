import 'package:flutter/material.dart';

import 'teacher_leave_page.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 1200
                ? 32.0
                : constraints.maxWidth >= 700
                ? 24.0
                : 16.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        24,
                        horizontalPadding,
                        20,
                      ),
                      sliver: const SliverToBoxAdapter(
                        child: _DashboardHeader(),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        32,
                      ),
                      sliver: SliverLayoutBuilder(
                        builder: (context, sliverConstraints) {
                          final width = sliverConstraints.crossAxisExtent;

                          final columnCount = width >= 900
                              ? 3
                              : width >= 560
                              ? 2
                              : 1;

                          return SliverGrid(
                            delegate: SliverChildListDelegate.fixed([
                              _StaffDashboardCard(
                                title: 'Staff Directory',
                                description:
                                    'View, search, edit and manage all staff records.',
                                icon: Icons.groups_outlined,
                                actionLabel: 'View Staff',
                                onTap: onViewStaff,
                              ),
                              _StaffDashboardCard(
                                title: 'Add Staff',
                                description:
                                    'Register a new staff member and employment details.',
                                icon: Icons.person_add_alt_1_outlined,
                                actionLabel: 'Add Staff',
                                onTap: onAddStaff,
                              ),
                              _StaffDashboardCard(
                                title: 'Staff Attendance',
                                description:
                                    'Mark daily attendance and review attendance records.',
                                icon: Icons.fact_check_outlined,
                                actionLabel: 'Open Attendance',
                                onTap: onAttendance,
                              ),
                              _StaffDashboardCard(
                                title: 'Salary Management',
                                description:
                                    'Generate salaries, record payments and review salary history.',
                                icon: Icons.payments_outlined,
                                actionLabel: 'Open Salary',
                                onTap: onSalary,
                              ),
                              _StaffDashboardCard(
                                title: 'Teacher Leave',
                                description:
                                    'Create, approve and review teacher leave requests.',
                                icon: Icons.school_outlined,
                                actionLabel: 'Open Teacher Leave',
                                onTap: () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const TeacherLeavePage(),
                                    ),
                                  );
                                },
                              ),
                              _StaffDashboardCard(
                                title: 'Leave Management',
                                description:
                                    'Create, approve and review staff leave requests.',
                                icon: Icons.event_available_outlined,
                                actionLabel: 'Open Leave',
                                onTap: onLeave,
                              ),
                            ]),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columnCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: 220,
                                ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;

            final icon = Container(
              width: 68,
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.badge_outlined,
                size: 36,
                color: theme.colorScheme.onPrimary,
              ),
            );

            final information = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Management',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage staff profiles, attendance, salaries and employment records.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [icon, const SizedBox(height: 18), information],
              );
            }

            return Row(
              children: [
                icon,
                const SizedBox(width: 20),
                Expanded(child: information),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StaffDashboardCard extends StatelessWidget {
  const _StaffDashboardCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      actionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
