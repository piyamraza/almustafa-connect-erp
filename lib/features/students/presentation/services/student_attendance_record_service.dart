import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../domain/entities/student_entity.dart';

class StudentAttendanceRecordService {
  const StudentAttendanceRecordService();

  static const _schoolName = 'Almustafa Model School';
  static const _schoolAddress = 'VIP Colony, Suraj Miani, Multan';

  Future<Uint8List> buildPdf({
    required StudentEntity student,
    required String className,
    required String sectionName,
    required DateTime fromDate,
    required DateTime toDate,
    required List<AttendanceEntity> records,
  }) async {
    final ordered = List<AttendanceEntity>.of(records)
      ..sort(
        (first, second) =>
            first.attendanceDate.compareTo(second.attendanceDate),
      );
    final present = ordered
        .where(
          (record) =>
              record.status == AttendanceStatus.present ||
              record.status == AttendanceStatus.late,
        )
        .length;
    final absent = ordered
        .where((record) => record.status == AttendanceStatus.absent)
        .length;
    final leave = ordered
        .where((record) => record.status == AttendanceStatus.leave)
        .length;
    final late = ordered
        .where((record) => record.status == AttendanceStatus.late)
        .length;
    final percentage = ordered.isEmpty ? 0.0 : present * 100 / ordered.length;
    final chunks = <List<AttendanceEntity>>[];
    for (var index = 0; index < ordered.length; index += 8) {
      chunks.add(
        ordered.sublist(index, (index + 8).clamp(0, ordered.length).toInt()),
      );
    }

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _schoolName,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(_schoolAddress, style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 4),
            pw.Text(
              'STUDENT ATTENDANCE RECORD',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(color: PdfColors.blueGrey300),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Generated: ${_date(DateTime.now())}  |  Page ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.blueGrey700,
            ),
          ),
        ),
        build: (_) => [
          pw.Wrap(
            spacing: 24,
            runSpacing: 5,
            children: [
              _meta('Student', student.fullName),
              _meta('Admission No.', student.admissionNo),
              _meta(
                'Roll No.',
                student.rollNumber.isEmpty ? '-' : student.rollNumber,
              ),
              _meta('Class', className),
              _meta('Section', sectionName),
              _meta('Period', '${_date(fromDate)} - ${_date(toDate)}'),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Days',
              'Present',
              'Absent',
              'Leave',
              'Late',
              'Attendance',
            ],
            data: [
              [
                ordered.length,
                present,
                absent,
                leave,
                late,
                '${percentage.toStringAsFixed(1)}%',
              ],
            ],
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey100,
            ),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.center,
          ),
          pw.SizedBox(height: 18),
          if (ordered.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey300),
              ),
              child: pw.Text(
                'No attendance record found for the selected period.',
                textAlign: pw.TextAlign.center,
              ),
            )
          else ...[
            pw.Text(
              'Date-wise Attendance',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            for (final chunk in chunks) ...[
              _attendanceTable(chunk),
              pw.SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _attendanceTable(List<AttendanceEntity> records) {
    return pw.TableHelper.fromTextArray(
      headers: [
        'Date',
        ...records.map((record) => _shortDate(record.attendanceDate)),
      ],
      data: [
        ['Status', ...records.map((record) => _status(record.status))],
      ],
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.center,
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerHeight: 28,
      cellHeight: 30,
    );
  }

  pw.Widget _meta(String label, String value) => pw.RichText(
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: '$label: ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.TextSpan(text: value),
      ],
    ),
  );

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String _shortDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';

  static String _status(AttendanceStatus status) => switch (status) {
    AttendanceStatus.present => 'Present',
    AttendanceStatus.absent => 'Absent',
    AttendanceStatus.leave => 'Leave',
    AttendanceStatus.late => 'Late',
  };
}
