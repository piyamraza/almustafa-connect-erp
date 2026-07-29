import 'package:flutter/material.dart';

import '../../../students/presentation/pages/students_page.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';
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
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
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
      MaterialPageRoute(
        builder: (_) => const StudentsPage(),
      ),
    );
  },
),

          _menuTile(
            context,
            icon: Icons.person,
            title: 'Teachers',
            onTap: () {},
          ),

          _menuTile(
            context,
            icon: Icons.badge,
            title: 'Staff',
            onTap: () {},
          ),

          _menuTile(
            context,
            icon: Icons.class_,
            title: 'Classes',
            onTap: () {},
          ),

          _menuTile(
            context,
            icon: Icons.groups,
            title: 'Sections',
            onTap: () {},
          ),

                    _menuTile(
            context,
            icon: Icons.fact_check,
            title: 'Attendance',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AttendancePage(),
                ),
              );
            },
          ),

          _menuTile(
            context,
            icon: Icons.payments,
            title: 'Fee Management',
            onTap: () {},
          ),

          _menuTile(
            context,
            icon: Icons.quiz,
            title: 'Examinations',
            onTap: () {},
          ),

          _menuTile(
            context,
            icon: Icons.grade,
            title: 'Results',
            onTap: () {},
          ),

          _menuTile(
            context,
            icon: Icons.schedule,
            title: 'Timetable',
            onTap: () {},
          ),

          _menuTile(
            context,
            icon: Icons.local_library,
            title: 'Library',
            onTap: () {},
          ),

                    _menuTile(
            context,
            icon: Icons.family_restroom,
            title: 'Parents',
            onTap: () {},
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
      leading: Icon(
        icon,
        color: Colors.white,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }
}