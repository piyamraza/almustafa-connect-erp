import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../../core/widgets/app_page_layout.dart';
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
import '../../../teacher_portal/presentation/pages/teacher_portal_preview_page.dart';
import '../../../teachers/presentation/pages/teachers_module_page.dart';
import 'employee_certificates_page.dart';
import 'teacher_appointment_letters_page.dart';

class EmployeeHrPage extends StatelessWidget {
  const EmployeeHrPage({super.key});

  static const _blue = Color(0xFF1265E8);
  static const _navy = Color(0xFF0B3D91);

  @override
  Widget build(BuildContext context) {
    final access = sl<AccessControlService>();
    final items = <_HrAction>[
      _HrAction(
        title: 'Teachers',
        subtitle: 'Profiles, assignments, workload, leave and reports',
        icon: Icons.school_rounded,
        color: const Color(0xFF246BFD),
        enabled: access.hasPermission(AppPermission.teachersView),
        onTap: () => _open(context, const TeachersModulePage()),
      ),
      _HrAction(
        title: 'Staff',
        subtitle: 'Directory, attendance, salary and leave management',
        icon: Icons.groups_rounded,
        color: const Color(0xFF0AA47A),
        enabled: access.hasPermission(AppPermission.staffView),
        onTap: () => _openStaff(context, access),
      ),
      _HrAction(
        title: 'Substitute Duties',
        subtitle: 'Arrange and monitor substitute teacher duties',
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFF8B5CF6),
        enabled: access.hasPermission(AppPermission.staffView),
        onTap: () => _open(context, const SubstituteDutyManagementPage()),
      ),
      _HrAction(
        title: 'Teacher Portal Preview',
        subtitle: 'Preview the portal and daily workspace for any teacher',
        icon: Icons.preview_outlined,
        color: const Color(0xFF2563EB),
        enabled:
            access.hasPermission(AppPermission.teachersView) ||
            access.hasPermission(AppPermission.staffView),
        onTap: () => _open(context, const TeacherPortalPreviewPage()),
      ),
      _HrAction(
        title: 'Appointment Letters',
        subtitle: 'Issue, sign and retain teacher appointment records',
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFFE8553D),
        enabled: access.hasPermission(AppPermission.teachersView),
        onTap: () => _open(context, const TeacherAppointmentLettersPage()),
      ),
      _HrAction(
        title: 'Employee Documents',
        subtitle: 'Generate cards, certificates and official records',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFF59E0B),
        enabled: true,
        onTap: () => _open(context, const EmployeeCertificatesPage()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee / HR'),
        actions: const [DashboardNavigationButton()],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth >= 900 ? 24.0 : 16.0;
            final columns = constraints.maxWidth >= 1150
                ? 4
                : constraints.maxWidth >= 680
                ? 2
                : 2;
            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HrHero(),
                      const SizedBox(height: 22),
                      Text(
                        'Workforce Management',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF12213F),
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Everything needed to manage your school team.',
                        style: TextStyle(color: Colors.blueGrey.shade600),
                      ),
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: constraints.maxWidth < 680
                              ? 126
                              : 196,
                        ),
                        itemBuilder: (_, index) =>
                            _HrActionCard(item: items[index]),
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

  static void _openStaff(BuildContext context, AccessControlService access) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (staffContext) => StaffDashboardPage(
          onViewStaff: () => _open(staffContext, const StaffListPage()),
          onAddStaff: () {
            if (!access.hasPermission(AppPermission.staffCreate)) {
              _open(
                staffContext,
                const UnauthorizedAccessPage(moduleName: 'Create Staff'),
              );
              return;
            }
            _open(staffContext, const AddStaffPage());
          },
          onAttendance: () => _open(staffContext, const StaffAttendancePage()),
          onSalary: () => _open(staffContext, const StaffSalaryPage()),
          onLeave: () => _open(staffContext, const StaffLeavePage()),
        ),
      ),
    );
  }

  static void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class _HrHero extends StatelessWidget {
  const _HrHero();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 600) {
      return const AppModuleHero(
        title: 'People & Culture Center',
        description: 'Manage teachers and staff from one workspace.',
        icon: Icons.badge_rounded,
        decorativeIcon: Icons.people_alt_rounded,
        colors: [EmployeeHrPage._blue, EmployeeHrPage._navy],
      );
    }
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EmployeeHrPage._blue, EmployeeHrPage._navy],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331265E8),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: .24)),
            ),
            child: const Icon(
              Icons.badge_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'People & Culture Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Manage teachers and staff from one organised workspace.',
                  style: TextStyle(color: Color(0xFFE8F1FF), fontSize: 15),
                ),
              ],
            ),
          ),
          Icon(
            Icons.people_alt_rounded,
            size: 104,
            color: Colors.white.withValues(alpha: .08),
          ),
        ],
      ),
    );
  }
}

class _HrAction {
  const _HrAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
}

class _HrActionCard extends StatefulWidget {
  const _HrActionCard({required this.item});
  final _HrAction item;

  @override
  State<_HrActionCard> createState() => _HrActionCardState();
}

class _HrActionCardState extends State<_HrActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = item.enabled ? item.color : Colors.blueGrey;
    final compact = MediaQuery.sizeOf(context).width < 680;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: color.withValues(alpha: _hovered ? .42 : .18),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: _hovered ? .18 : .08),
              blurRadius: _hovered ? 24 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: item.enabled ? item.onTap : null,
            child: Padding(
              padding: EdgeInsets.all(compact ? 12 : 20),
              child: compact
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [color.withValues(alpha: .72), color],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .45),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: .28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(item.icon, color: Colors.white, size: 21),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.title,
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
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [color.withValues(alpha: .68), color],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: .3),
                                    blurRadius: 13,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                item.icon,
                                color: Colors.white,
                                size: 29,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_outward_rounded, color: color),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF14213D),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.enabled
                              ? item.subtitle
                              : 'You do not have access.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            height: 1.35,
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
