import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../domain/entities/student_entity.dart';
import '../services/student_attendance_record_service.dart';

class StudentAttendanceRecordPreviewPage extends StatelessWidget {
  const StudentAttendanceRecordPreviewPage({
    super.key,
    required this.student,
    required this.className,
    required this.sectionName,
    required this.fromDate,
    required this.toDate,
    required this.records,
  });

  final StudentEntity student;
  final String className;
  final String sectionName;
  final DateTime fromDate;
  final DateTime toDate;
  final List<AttendanceEntity> records;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Record Preview')),
      body: PdfPreview(
        pdfFileName: _fileName(),
        initialPageFormat: PdfPageFormat.a4,
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
        build: (_) => const StudentAttendanceRecordService().buildPdf(
          student: student,
          className: className,
          sectionName: sectionName,
          fromDate: fromDate,
          toDate: toDate,
          records: records,
        ),
      ),
    );
  }

  String _fileName() {
    final safeName = student.fullName
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return '${safeName.isEmpty ? 'student' : safeName}_attendance_record.pdf';
  }
}
