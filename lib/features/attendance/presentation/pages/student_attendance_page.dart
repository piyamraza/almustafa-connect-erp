import 'package:flutter/material.dart';

class StudentAttendancePage extends StatelessWidget {
  const StudentAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance'),
      ),
      body: const Center(
        child: Text(
          'Student Attendance\nComing Soon',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}