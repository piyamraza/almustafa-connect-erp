import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/class_timetable_entry_entity.dart';
import '../../domain/entities/teacher_workload_entity.dart';
import '../../domain/entities/timetable_report_entity.dart';
import '../../domain/entities/timetable_period_entity.dart';
import '../../domain/services/timetable_report_export_service.dart';

class TimetableReportExportServiceImpl implements TimetableReportExportService {
  static const _schoolName = 'Almustafa Model School';
  static const _schoolAddress = 'VIP Colony, Suraj Miani, Multan';

  @override
  Future<Uint8List> buildPdf(TimetableReportEntity report) async {
    final document = pw.Document();
    final logo = await _loadLogo();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => _buildHeader(logo, report),
        footer: _buildFooter,
        build: (_) => report.request.type == TimetableReportType.teacherWorkload
            ? _buildWorkloadPdf(report)
            : _buildTimetablePdf(report),
      ),
    );

    return document.save();
  }

  @override
  Future<Uint8List> buildExcel(TimetableReportEntity report) async {
    final workbook = Excel.createExcel();
    final sheetName = switch (report.request.type) {
      TimetableReportType.classTimetable => 'Class Timetable',
      TimetableReportType.teacherTimetable => 'Teacher Timetable',
      TimetableReportType.teacherWorkload => 'Teacher Workload',
    };
    final sheet = workbook[sheetName];

    _appendExcelMetadata(sheet, report);

    if (report.request.type == TimetableReportType.teacherWorkload) {
      _appendWorkloadExcel(sheet, report);
    } else {
      _appendTimetableExcel(sheet, report);
    }

    workbook.delete('Sheet1');
    final encoded = workbook.encode();
    if (encoded == null) {
      throw StateError('Unable to create the timetable Excel workbook.');
    }

    return Uint8List.fromList(encoded);
  }

  @override
  Future<void> printPdf(TimetableReportEntity report) async {
    final bytes = await buildPdf(report);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Future<void> sharePdf(TimetableReportEntity report) async {
    final bytes = await buildPdf(report);
    await Printing.sharePdf(bytes: bytes, filename: _fileName(report, 'pdf'));
  }

  @override
  Future<void> exportExcel(TimetableReportEntity report) async {
    final bytes = await buildExcel(report);
    Share.downloadFallbackEnabled = true;
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      fileNameOverrides: [_fileName(report, 'xlsx')],
      subject: report.request.reportTitle,
    );
  }

  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/images/logo.jpeg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  pw.Widget _buildHeader(pw.ImageProvider? logo, TimetableReportEntity report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logo != null)
              pw.Container(
                width: 42,
                height: 42,
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                  image: pw.DecorationImage(image: logo, fit: pw.BoxFit.cover),
                ),
              )
            else
              pw.Container(
                width: 42,
                height: 42,
                alignment: pw.Alignment.center,
                color: PdfColors.blueGrey100,
                child: pw.Text(
                  'AMS',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _schoolName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _schoolAddress,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    report.request.reportTitle.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.Text(
              report.request.academicSession,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 7),
        pw.Wrap(
          spacing: 14,
          runSpacing: 3,
          children: report.request.filters.entries
              .where((entry) => entry.value.trim().isNotEmpty)
              .map(
                (entry) => pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: '${entry.key}: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(text: entry.value),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        ),
        pw.Divider(color: PdfColors.blueGrey300),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Generated ${_dateTime(DateTime.now())}  |  '
        'Page ${context.pageNumber}/${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey700),
      ),
    );
  }

  List<pw.Widget> _buildTimetablePdf(TimetableReportEntity report) {
    final periods = _teachingPeriods(report);
    final days = _workingDays(report);
    final bySlot = <String, ClassTimetableEntryEntity>{
      for (final entry in report.entries)
        '${entry.weekday}|${entry.periodId}': entry,
    };

    final headers = <String>[
      'Day',
      for (final period in periods)
        '${period.label}\n'
            '${_formatMinutes(period.startMinutes)}-'
            '${_formatMinutes(period.endMinutes)}',
    ];

    final rows = <List<String>>[
      for (final day in days)
        <String>[
          _dayName(day),
          for (final period in periods)
            _timetableCellText(
              report.request.type,
              bySlot['$day|${period.id}'],
            ),
        ],
    ];

    return [
      pw.SizedBox(height: 8),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            report.request.reportSubject,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${report.assignedPeriods} assigned periods',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
        headerStyle: pw.TextStyle(
          fontSize: 6.2,
          fontWeight: pw.FontWeight.bold,
        ),
        cellStyle: const pw.TextStyle(fontSize: 5.8),
        cellAlignment: pw.Alignment.center,
        headerAlignment: pw.Alignment.center,
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        border: pw.TableBorder.all(color: PdfColors.blueGrey300, width: 0.5),
      ),
    ];
  }

  List<pw.Widget> _buildWorkloadPdf(TimetableReportEntity report) {
    final totalAssigned = report.totalWorkloadPeriods;
    final average = report.workloads.isEmpty
        ? 0.0
        : totalAssigned / report.workloads.length;

    return [
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: const [
          'Active Teachers',
          'Assigned Periods',
          'Average / Teacher',
          'High Workload',
          'Unassigned',
        ],
        data: [
          [
            '${report.workloads.length}',
            '$totalAssigned',
            average.toStringAsFixed(1),
            '${report.workloads.where((item) => item.level == TeacherWorkloadLevel.high).length}',
            '${report.workloads.where((item) => item.level == TeacherWorkloadLevel.unassigned).length}',
          ],
        ],
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
        headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 7),
        cellAlignment: pw.Alignment.center,
      ),
      pw.SizedBox(height: 12),
      pw.TableHelper.fromTextArray(
        headers: const [
          'Employee ID',
          'Teacher',
          'Designation',
          'Assigned',
          'Free',
          'Days',
          'Classes',
          'Subjects',
          'Utilization',
          'Status',
        ],
        data: report.workloads
            .map(
              (workload) => [
                workload.employeeId,
                workload.teacherName,
                workload.designation,
                '${workload.assignedPeriods}',
                '${workload.freePeriods}',
                '${workload.teachingDays}',
                '${workload.classSections.length}',
                '${workload.subjects.length}',
                '${(workload.utilization * 100).round()}%',
                _workloadLevelLabel(workload.level),
              ],
            )
            .toList(growable: false),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
        headerStyle: pw.TextStyle(
          fontSize: 6.3,
          fontWeight: pw.FontWeight.bold,
        ),
        cellStyle: const pw.TextStyle(fontSize: 5.8),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        border: pw.TableBorder.all(color: PdfColors.blueGrey300, width: 0.5),
      ),
    ];
  }

  void _appendExcelMetadata(Sheet sheet, TimetableReportEntity report) {
    sheet.appendRow([TextCellValue(_schoolName)]);
    sheet.appendRow([TextCellValue(_schoolAddress)]);
    sheet.appendRow([TextCellValue(report.request.reportTitle)]);

    for (final entry in report.request.filters.entries) {
      if (entry.value.trim().isNotEmpty) {
        sheet.appendRow([TextCellValue(entry.key), TextCellValue(entry.value)]);
      }
    }

    sheet.appendRow([
      TextCellValue('Generated'),
      TextCellValue(_dateTime(report.generatedAt)),
    ]);
    sheet.appendRow([]);
  }

  void _appendTimetableExcel(Sheet sheet, TimetableReportEntity report) {
    final periods = _teachingPeriods(report);
    final days = _workingDays(report);
    final bySlot = <String, ClassTimetableEntryEntity>{
      for (final entry in report.entries)
        '${entry.weekday}|${entry.periodId}': entry,
    };

    sheet.appendRow([
      TextCellValue('Day'),
      for (final period in periods)
        TextCellValue(
          '${period.label} '
          '(${_formatMinutes(period.startMinutes)} - '
          '${_formatMinutes(period.endMinutes)})',
        ),
    ]);

    for (final day in days) {
      sheet.appendRow([
        TextCellValue(_dayName(day)),
        for (final period in periods)
          TextCellValue(
            _timetableCellText(
              report.request.type,
              bySlot['$day|${period.id}'],
            ),
          ),
      ]);
    }

    sheet.setColumnWidth(0, 15);
    for (var index = 1; index <= periods.length; index++) {
      sheet.setColumnWidth(index, 24);
    }
  }

  void _appendWorkloadExcel(Sheet sheet, TimetableReportEntity report) {
    sheet.appendRow([
      TextCellValue('Employee ID'),
      TextCellValue('Teacher'),
      TextCellValue('Designation'),
      TextCellValue('Assigned Periods'),
      TextCellValue('Free Periods'),
      TextCellValue('Teaching Days'),
      TextCellValue('Classes / Sections'),
      TextCellValue('Subjects'),
      TextCellValue('Utilization'),
      TextCellValue('Status'),
    ]);

    for (final workload in report.workloads) {
      sheet.appendRow([
        TextCellValue(workload.employeeId),
        TextCellValue(workload.teacherName),
        TextCellValue(workload.designation),
        IntCellValue(workload.assignedPeriods),
        IntCellValue(workload.freePeriods),
        IntCellValue(workload.teachingDays),
        TextCellValue(workload.classSections.join(', ')),
        TextCellValue(workload.subjects.join(', ')),
        TextCellValue('${(workload.utilization * 100).round()}%'),
        TextCellValue(_workloadLevelLabel(workload.level)),
      ]);
    }

    sheet.setColumnWidth(0, 15);
    sheet.setColumnWidth(1, 24);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 16);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 32);
    sheet.setColumnWidth(7, 32);
    sheet.setColumnWidth(8, 14);
    sheet.setColumnWidth(9, 14);
  }

  List<TimetablePeriodEntity> _teachingPeriods(TimetableReportEntity report) {
    return report.configuration.orderedPeriods
        .where((period) => period.isTeaching)
        .toList(growable: false);
  }

  List<int> _workingDays(TimetableReportEntity report) {
    final days = report.configuration.workingDays.toList()..sort();
    return days;
  }

  String _timetableCellText(
    TimetableReportType type,
    ClassTimetableEntryEntity? entry,
  ) {
    if (entry == null) {
      return type == TimetableReportType.teacherTimetable
          ? 'Free'
          : 'Not Assigned';
    }

    return switch (type) {
      TimetableReportType.classTimetable =>
        '${entry.subjectName}\n${entry.teacherName}',
      TimetableReportType.teacherTimetable =>
        '${entry.subjectName}\n${entry.className} - ${entry.sectionName}',
      TimetableReportType.teacherWorkload => '',
    };
  }

  String _fileName(TimetableReportEntity report, String extension) {
    final parts =
        <String>[
              report.request.reportTitle,
              report.request.reportSubject,
              report.request.academicSession,
            ]
            .where((value) => value.trim().isNotEmpty)
            .map(_safeFileSegment)
            .toList(growable: false);

    return '${parts.join('_')}.$extension';
  }

  String _safeFileSegment(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? 'Timetable_Report' : cleaned;
  }

  String _dayName(int weekday) => switch (weekday) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    DateTime.sunday => 'Sunday',
    _ => 'Day',
  };

  String _formatMinutes(int value) {
    final hour = value ~/ 60;
    final minute = value % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _workloadLevelLabel(TeacherWorkloadLevel level) => switch (level) {
    TeacherWorkloadLevel.unassigned => 'Unassigned',
    TeacherWorkloadLevel.low => 'Low',
    TeacherWorkloadLevel.balanced => 'Balanced',
    TeacherWorkloadLevel.high => 'High',
  };

  String _dateTime(DateTime value) {
    final date =
        '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
    final time =
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
