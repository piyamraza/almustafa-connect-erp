import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../access_control/domain/entities/app_permission.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../../access_control/presentation/pages/unauthorized_access_page.dart';
import '../../../staff/presentation/pages/add_staff_page.dart';
import '../../../staff/presentation/pages/staff_attendance_page.dart';
import '../../../staff/presentation/pages/staff_dashboard_page.dart';
import '../../../staff/presentation/pages/staff_leave_page.dart';
import '../../../staff/presentation/pages/staff_list_page.dart';
import '../../../staff/presentation/pages/staff_salary_page.dart';
import '../../../teacher_portal/presentation/pages/substitute_duty_management_page.dart';
import '../../../teachers/presentation/pages/teachers_module_page.dart';
import 'employee_certificates_page.dart';

class EmployeeHrPage extends StatelessWidget {
  const EmployeeHrPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final access =
        sl<AccessControlService>();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Employee / HR'),
        actions: const [
          DashboardNavigationButton(),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final columns =
                constraints.maxWidth >= 1000
                    ? 4
                    : constraints.maxWidth >= 650
                    ? 2
                    : 1;

            return SingleChildScrollView(
              padding:
                  const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 1250,
                  ),
                  child: GridView.count(
                    crossAxisCount:
                        columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    children: [
                      _HrCard(
                        title: 'Teachers',
                        icon:
                            Icons.school_outlined,
                        enabled:
                            access.hasPermission(
                          AppPermission.teachersView,
                        ),
                        onTap: () => _open(
                          context,
                          const TeachersModulePage(),
                        ),
                      ),
                      _HrCard(
                        title: 'Staff',
                        icon:
                            Icons.groups_outlined,
                        enabled:
                            access.hasPermission(
                          AppPermission.staffView,
                        ),
                        onTap: () =>
                            _openStaff(
                          context,
                          access,
                        ),
                      ),
                      _HrCard(
                        title:
                            'Substitute Duties',
                        icon:
                            Icons.swap_horiz,
                        enabled:
                            access.hasPermission(
                          AppPermission.staffView,
                        ),
                        onTap: () => _open(
                          context,
                          const SubstituteDutyManagementPage(),
                        ),
                      ),
                      _HrCard(
                        title: 'Certificates',
                        icon:
                            Icons.workspace_premium_outlined,
                        enabled: true,
                        onTap: () => _open(
                          context,
                          const EmployeeCertificatesPage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static void _openStaff(
    BuildContext context,
    AccessControlService access,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (
          staffDashboardContext,
        ) =>
            StaffDashboardPage(
          onViewStaff: () {
            Navigator.of(
              staffDashboardContext,
            ).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const StaffListPage(),
              ),
            );
          },
          onAddStaff: () {
            if (!access.hasPermission(
              AppPermission.staffCreate,
            )) {
              Navigator.of(
                staffDashboardContext,
              ).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const UnauthorizedAccessPage(
                    moduleName:
                        'Create Staff',
                  ),
                ),
              );
              return;
            }

            Navigator.of(
              staffDashboardContext,
            ).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const AddStaffPage(),
              ),
            );
          },
          onAttendance: () {
            Navigator.of(
              staffDashboardContext,
            ).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const StaffAttendancePage(),
              ),
            );
          },
          onSalary: () {
            Navigator.of(
              staffDashboardContext,
            ).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const StaffSalaryPage(),
              ),
            );
          },
          onLeave: () {
            Navigator.of(
              staffDashboardContext,
            ).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const StaffLeavePage(),
              ),
            );
          },
        ),
      ),
    );
  }

  static void _open(
    BuildContext context,
    Widget page,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => page,
      ),
    );
  }
}

class _HrCard extends StatelessWidget {
  const _HrCard({
    required this.title,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            enabled ? onTap : null,
        child: Padding(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 38,
                color: enabled
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                    : Colors.grey,
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                enabled
                    ? 'Open'
                    : 'No Access',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
