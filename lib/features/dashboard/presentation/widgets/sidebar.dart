import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../access_control/domain/entities/app_permission.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../../access_control/presentation/pages/roles_permissions_page.dart';
import '../../../access_control/presentation/pages/unauthorized_access_page.dart';
import '../../../authentication/domain/usecases/logout_usecase.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../accounts/presentation/pages/accounts_dashboard_page.dart';
import '../../../academic_calendar/presentation/pages/academic_calendar_page.dart';
import '../../../academic_structure/presentation/pages/class_section_management_page.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../communication/presentation/pages/communication_dashboard_page.dart';
import '../../../exams/presentation/pages/exam_date_sheet_dashboard_page.dart';
import '../../../exams/presentation/pages/examination_dashboard_page.dart';
import '../../../fees/presentation/pages/fee_management_dashboard_page.dart';
import '../../../homework/presentation/pages/homework_dashboard_page.dart';
import '../../../notices/presentation/pages/notices_dashboard_page.dart';
import '../../../parent_portal/presentation/pages/parent_portal_dashboard_page.dart';
import '../../../results/presentation/pages/results_module_page.dart';
import '../../../reports/presentation/pages/reports_dashboard_page.dart';
import '../../../school_store/presentation/pages/school_store_dashboard_page.dart';
import '../../../settings/presentation/pages/settings_dashboard_page.dart';
import '../../../staff/presentation/pages/add_staff_page.dart';
import '../../../staff/presentation/pages/staff_attendance_page.dart';
import '../../../staff/presentation/pages/staff_dashboard_page.dart';
import '../../../staff/presentation/pages/staff_leave_page.dart';
import '../../../staff/presentation/pages/staff_list_page.dart';
import '../../../staff/presentation/pages/staff_salary_page.dart';
import '../../../students/presentation/pages/students_page.dart';
import '../../../teachers/presentation/pages/teachers_module_page.dart';
import '../../../timetable/presentation/pages/timetable_dashboard_page.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late final AccessControlService _access;
  final ScrollController _scrollController = ScrollController();
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _access = sl<AccessControlService>();
    _access.addListener(_refresh);
    _access.loadCurrentAccess();
  }

  @override
  void dispose() {
    _access.removeListener(_refresh);
    _scrollController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _logout(BuildContext context) async {
    if (_loggingOut) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;
    setState(() => _loggingOut = true);

    try {
      await sl<LogoutUseCase>()();
      await _access.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Logout failed: $error')),
        );
    }
  }

  void _open(
    BuildContext context, {
    required AppPermission permission,
    required String moduleName,
    required Widget page,
  }) {
    if (!_access.hasPermission(permission)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UnauthorizedAccessPage(moduleName: moduleName),
        ),
      );
      return;
    }

    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF5FF), Color(0xFFCFE7FF)],
        ),
      ),
      child: _access.isLoading || !_access.isLoaded
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF102A43)),
            )
          : ScrollbarTheme(
              data: ScrollbarThemeData(
                thumbColor: WidgetStateProperty.all(const Color(0xFF102A43)),
                trackColor: WidgetStateProperty.all(const Color(0xFF9FC8EE)),
                trackBorderColor: WidgetStateProperty.all(
                  const Color(0xFF79ACD8),
                ),
                thickness: WidgetStateProperty.all(8),
                radius: const Radius.circular(8),
              ),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: true,
                interactive: true,
                child: ListView(
                  controller: _scrollController,
                  primary: false,
                  padding: const EdgeInsets.fromLTRB(0, 16, 12, 16),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        'MAIN MENU',
                        style: TextStyle(
                          color: Color(0xFF183B5B),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (_access.isBootstrapAccess)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Text(
                          'Bootstrap access: assign this user a role.',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.studentsView))
                      _menuTile(
                        context,
                        icon: Icons.school,
                        title: 'Students',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.studentsView,
                          moduleName: 'Students',
                          page: const StudentsPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.teachersView))
                      _menuTile(
                        context,
                        icon: Icons.person,
                        title: 'Teachers',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.teachersView,
                          moduleName: 'Teachers',
                          page: const TeachersModulePage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.staffView))
                      _menuTile(
                        context,
                        icon: Icons.badge,
                        title: 'Staff',
                        onTap: () {
                          if (!_access.hasPermission(AppPermission.staffView)) {
                            _open(
                              context,
                              permission: AppPermission.staffView,
                              moduleName: 'Staff',
                              page: const SizedBox.shrink(),
                            );
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (staffDashboardContext) {
                                return StaffDashboardPage(
                                  onViewStaff: () {
                                    Navigator.of(staffDashboardContext).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const StaffListPage(),
                                      ),
                                    );
                                  },
                                  onAttendance: () {
                                    Navigator.of(staffDashboardContext).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const StaffAttendancePage(),
                                      ),
                                    );
                                  },
                                  onLeave: () {
                                    Navigator.of(staffDashboardContext).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const StaffLeavePage(),
                                      ),
                                    );
                                  },
                                  onSalary: () {
                                    Navigator.of(staffDashboardContext).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const StaffSalaryPage(),
                                      ),
                                    );
                                  },
                                  onAddStaff: () {
                                    if (!_access.hasPermission(
                                      AppPermission.staffCreate,
                                    )) {
                                      Navigator.of(staffDashboardContext).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const UnauthorizedAccessPage(
                                                moduleName: 'Create Staff',
                                              ),
                                        ),
                                      );
                                      return;
                                    }

                                    Navigator.of(staffDashboardContext).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const AddStaffPage(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    if (_access.hasPermission(AppPermission.classesView))
                      _menuTile(
                        context,
                        icon: Icons.class_,
                        title: 'Classes',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.classesView,
                          moduleName: 'Classes',
                          page: const ClassSectionManagementPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.attendanceView))
                      _menuTile(
                        context,
                        icon: Icons.fact_check,
                        title: 'Attendance',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.attendanceView,
                          moduleName: 'Attendance',
                          page: const AttendancePage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.feesView))
                      _menuTile(
                        context,
                        icon: Icons.payments,
                        title: 'Fee Management',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.feesView,
                          moduleName: 'Fee Management',
                          page: const FeeManagementDashboardPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.examsView))
                      _menuTile(
                        context,
                        icon: Icons.quiz,
                        title: 'Examinations',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.examsView,
                          moduleName: 'Examinations',
                          page: const ExaminationDashboardPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.dateSheetsView))
                      _menuTile(
                        context,
                        icon: Icons.calendar_month_outlined,
                        title: 'Date Sheets',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.dateSheetsView,
                          moduleName: 'Date Sheets',
                          page: const ExamDateSheetDashboardPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.resultsView))
                      _menuTile(
                        context,
                        icon: Icons.grade,
                        title: 'Results',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.resultsView,
                          moduleName: 'Results',
                          page: const ResultsModulePage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.timetableView))
                      _menuTile(
                        context,
                        icon: Icons.schedule,
                        title: 'Timetable',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.timetableView,
                          moduleName: 'Timetable',
                          page: const TimetableDashboardPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.homeworkView))
                      _menuTile(
                        context,
                        icon: Icons.menu_book_outlined,
                        title: 'Homework Management',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.homeworkView,
                          moduleName: 'Homework Management',
                          page: const HomeworkDashboardPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.calendarView))
                      _menuTile(
                        context,
                        icon: Icons.calendar_today_outlined,
                        title: 'Academic Calendar',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.calendarView,
                          moduleName: 'Academic Calendar',
                          page: const AcademicCalendarPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.noticesView))
                      _menuTile(
                        context,
                        icon: Icons.forum_outlined,
                        title: 'Communication',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.noticesView,
                          moduleName: 'Communication',
                          page: const CommunicationDashboardPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.noticesView))
                      _menuTile(
                        context,
                        icon: Icons.campaign_outlined,
                        title: 'Notices & Circulars',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.noticesView,
                          moduleName: 'Notices & Circulars',
                          page: const NoticesDashboardPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.parentsView))
                      _menuTile(
                        context,
                        icon: Icons.family_restroom,
                        title: 'Parents',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.parentsView,
                          moduleName: 'Parent Portal',
                          page: const ParentPortalDashboardPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.reportsView))
                      _menuTile(
                        context,
                        icon: Icons.account_balance_outlined,
                        title: 'Accounts & Payroll',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.reportsView,
                          moduleName: 'Accounts & Payroll',
                          page: const AccountsDashboardPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.reportsView))
                      _menuTile(
                        context,
                        icon: Icons.storefront_outlined,
                        title: 'School Store',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.reportsView,
                          moduleName: 'School Store',
                          page: const SchoolStoreDashboardPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.reportsView))
                      _menuTile(
                        context,
                        icon: Icons.assessment,
                        title: 'Reports',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.reportsView,
                          moduleName: 'Reports',
                          page: const ReportsDashboardPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.rolesManage))
                      _menuTile(
                        context,
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Roles & Permissions',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.rolesManage,
                          moduleName: 'Roles & Permissions',
                          page: const RolesPermissionsPage(),
                        ),
                      ),
                    if (_access.hasPermission(AppPermission.settingsView))
                      _menuTile(
                        context,
                        icon: Icons.settings,
                        title: 'Settings',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.settingsView,
                          moduleName: 'Settings',
                          page: const SettingsDashboardPage(),
                        ),
                      ),
                    const Divider(height: 28),
                    _menuTile(
                      context,
                      icon: Icons.logout_outlined,
                      title: _loggingOut ? 'Logging out...' : 'Logout',
                      onTap: _loggingOut ? () {} : () => _logout(context),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final color = _menuColor(title);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: .28)),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF17324D),
          fontWeight: FontWeight.w500,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      hoverColor: color.withValues(alpha: .10),
      onTap: onTap,
    );
  }

  Color _menuColor(String title) {
    return switch (title) {
      'Students' => const Color(0xFF61A5FA),
      'Teachers' => const Color(0xFF4ADE80),
      'Staff' => const Color(0xFFFBBF24),
      'Classes' => const Color(0xFFC084FC),
      'Attendance' => const Color(0xFF2DD4BF),
      'Fee Management' => const Color(0xFF34D399),
      'Examinations' => const Color(0xFFF472B6),
      'Date Sheets' => const Color(0xFF38BDF8),
      'Results' => const Color(0xFFFACC15),
      'Timetable' => const Color(0xFFA78BFA),
      'Homework Management' => const Color(0xFFFB923C),
      'Academic Calendar' => const Color(0xFF22D3EE),
      'Notices & Circulars' => const Color(0xFFFB7185),
      'Communication' => const Color(0xFF06B6D4),
      'Parents' => const Color(0xFF818CF8),
      'Accounts & Payroll' => const Color(0xFF0F766E),
      'School Store' => const Color(0xFF14B8A6),
      'Reports' => const Color(0xFF60A5FA),
      'Roles & Permissions' => const Color(0xFFE879F9),
      'Settings' => const Color(0xFF64748B),
      'Logout' => const Color(0xFFDC2626),
      'Logging out...' => const Color(0xFFDC2626),
      _ => const Color(0xFF94A3B8),
    };
  }
}
