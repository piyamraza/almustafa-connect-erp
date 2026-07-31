import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/attendance_report.dart';

class AttendanceReportExportService {
  static const schoolName = 'Almustafa Connect ERP';
  Future<Uint8List> pdf(AttendanceReport report) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            schoolName,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${_title(report.filter.type)} Attendance Report',
            style: const pw.TextStyle(fontSize: 16),
          ),
          pw.Text(
            'Period: ${_date(report.filter.fromDate)} - ${_date(report.filter.toDate)}',
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Present',
              'Absent',
              'Late',
              'Leave',
              'Attendance %',
              'Working days',
            ],
            data: [
              [
                report.statistics.present,
                report.statistics.absent,
                report.statistics.late,
                report.statistics.leave,
                '${report.statistics.percentage.toStringAsFixed(1)}%',
                report.statistics.workingDays,
              ],
            ],
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Date',
              'Admission #',
              'Student',
              'Class',
              'Section',
              'Status',
            ],
            data: report.records
                .map(
                  (r) => [
                    _date(r.attendanceDate),
                    r.admissionNo,
                    r.studentName,
                    r.classId,
                    r.sectionId,
                    r.status.name.toUpperCase(),
                  ],
                )
                .toList(),
          ),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Generated ${_date(DateTime.now())}  |  Page ${context.pageNumber}/${context.pagesCount}',
          ),
        ),
      ),
    );
    return document.save();
  }

  Future<void> print(AttendanceReport report) async =>
      Printing.layoutPdf(onLayout: (_) => pdf(report));
  Future<void> sharePdf(AttendanceReport report) async {
    final bytes = await pdf(report);
    final file = await _write('attendance_report.pdf', bytes);
    await Share.shareXFiles([XFile(file.path)], subject: 'Attendance report');
  }

  Future<void> shareExcel(AttendanceReport report) async {
    final excel = Excel.createExcel();
    final sheet = excel['Attendance Report'];
    sheet.appendRow([TextCellValue(schoolName)]);
    sheet.appendRow([
      TextCellValue('${_title(report.filter.type)} Attendance Report'),
    ]);
    sheet.appendRow([
      TextCellValue('Period'),
      TextCellValue(
        '${_date(report.filter.fromDate)} - ${_date(report.filter.toDate)}',
      ),
    ]);
    sheet.appendRow([
      TextCellValue('Present'),
      IntCellValue(report.statistics.present),
      TextCellValue('Absent'),
      IntCellValue(report.statistics.absent),
      TextCellValue('Late'),
      IntCellValue(report.statistics.late),
      TextCellValue('Leave'),
      IntCellValue(report.statistics.leave),
    ]);
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Admission #'),
      TextCellValue('Student'),
      TextCellValue('Class'),
      TextCellValue('Section'),
      TextCellValue('Status'),
    ]);
    for (final r in report.records) {
      sheet.appendRow([
        TextCellValue(_date(r.attendanceDate)),
        TextCellValue(r.admissionNo),
        TextCellValue(r.studentName),
        TextCellValue(r.classId),
        TextCellValue(r.sectionId),
        TextCellValue(r.status.name.toUpperCase()),
      ]);
    }
    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 28);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 14);
    final bytes = excel.encode();
    if (bytes == null) throw StateError('Unable to create Excel report.');
    final file = await _write(
      'attendance_report.xlsx',
      Uint8List.fromList(bytes),
    );
    await Share.shareXFiles([XFile(file.path)], subject: 'Attendance report');
  }

  Future<File> _write(String name, Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$name');
    return file.writeAsBytes(bytes, flush: true);
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  static String _title(AttendanceReportType value) => switch (value) {
    AttendanceReportType.daily => 'Daily',
    AttendanceReportType.monthly => 'Monthly',
    AttendanceReportType.dateRange => 'Date Range',
    AttendanceReportType.classWise => 'Class-wise',
    AttendanceReportType.sectionWise => 'Section-wise',
    AttendanceReportType.studentWise => 'Student-wise',
  };
}
