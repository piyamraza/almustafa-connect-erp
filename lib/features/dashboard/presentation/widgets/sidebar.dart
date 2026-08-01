import 'package:flutter/material.dart';

import '../../../academic_structure/presentation/pages/class_section_management_page.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../exams/presentation/pages/exam_date_sheet_dashboard_page.dart';
import '../../../fees/presentation/pages/fee_management_dashboard_page.dart';
import '../../../exams/presentation/pages/examination_dashboard_page.dart';
import '../../../results/presentation/pages/results_module_page.dart';
import '../../../staff/presentation/pages/add_staff_page.dart';
import '../../../staff/presentation/pages/staff_attendance_page.dart';
import '../../../staff/presentation/pages/staff_salary_page.dart';
import '../../../staff/presentation/pages/staff_leave_page.dart';
import '../../../staff/presentation/pages/staff_dashboard_page.dart';
import '../../../staff/presentation/pages/staff_list_page.dart';
import '../../../students/presentation/pages/students_page.dart';
import '../../../teachers/presentation/pages/teachers_module_page.dart';
import '../../../timetable/presentation/pages/timetable_dashboard_page.dart';

import '../../../academic_calendar/presentation/pages/academic_calendar_page.dart';

import '../../../homework/presentation/pages/homework_dashboard_page.dart';

import '../../../notices/presentation/pages/notices_dashboard_page.dart';

import '../../../parent_portal/presentation/pages/parent_portal_dashboard_page.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF263238),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'MAIN MENU',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.school,
            title: 'Students',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const StudentsPage()),
              );
            },
          ),
          _menuTile(
            context,
            icon: Icons.person,
            title: 'Teachers',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TeachersModulePage(),
                ),
              );
            },
          ),
          _menuTile(
            context,
            icon: Icons.badge,
            title: 'Staff',
            onTap: () {
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
                            builder: (_) => const StaffAttendancePage(),
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
          _menuTile(
            context,
            icon: Icons.class_,
            title: 'Classes',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ClassSectionManagementPage(),
                ),
              );
            },
          ),
          _menuTile(
            context,
            icon: Icons.fact_check,
            title: 'Attendance',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AttendancePage()),
              );
            },
          ),
          _menuTile(
            context,
            icon: Icons.payments,
            title: 'Fee Management',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FeeManagementDashboardPage(),
                ),
              );
            },
          ),
          _menuTile(
            context,
            icon: Icons.quiz,
            title: 'Examinations',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ExaminationDashboardPage(),
                ),
              );
            },
          ),
          _menuTile(
            context,
            icon: Icons.calendar_month_outlined,
            title: 'Date Sheets',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ExamDateSheetDashboardPage(),
                ),
              );
            },
          ),
          _menuTile(
            context,
            icon: Icons.grade,
            title: 'Results',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ResultsModulePage(),
                ),
              );
            },
          ),
          _menuTile(
            context,
            icon: Icons.schedule,
            title: 'Timetable',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TimetableDashboardPage(),
                ),
              );
            },
          ),
          _menuTile(
            context,
            icon: Icons.menu_book_outlined,
            title: 'Homework Management',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HomeworkDashboardPage(),
                ),
              );
            },
          ),
          _menuTile(
            context,
            icon: Icons.calendar_today_outlined,
            title: 'Academic Calendar',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AcademicCalendarPage(),
                ),
              );
            },
          ),
          _menuTile(
            context,
            icon: Icons.campaign_outlined,
            title: 'Notices & Circulars',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NoticesDashboardPage(),
                ),
              );
            },
          ),

          _menuTile(
            context,
            icon: Icons.family_restroom,
            title: 'Parents',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ParentPortalDashboardPage(),
                ),
              );
            },
          ),
          _menuTile(
            context,
            icon: Icons.assessment,
            title: 'Reports',
            onTap: () {},
          ),
          _menuTile(
            context,
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
