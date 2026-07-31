import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/exam_date_sheet_report_entity.dart';
import '../../domain/services/exam_date_sheet_report_service.dart';

class ExamDateSheetReportServiceImpl implements ExamDateSheetReportService {
  static const _schoolName = 'Almustafa Model School';
  static const _schoolAddress = 'VIP Colony, Suraj Miani, Multan';

  @override
  Future<void> printPdf(ExamDateSheetReportRequest request) async {
    final bytes = await _buildPdf(request);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Future<void> sharePdf(ExamDateSheetReportRequest request) async {
    final bytes = await _buildPdf(request);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_safeName(request.title)}_${_safeName(request.subject)}.pdf',
    );
  }

  @override
  Future<void> exportExcel(ExamDateSheetReportRequest request) async {
    final workbook = Excel.createExcel();
    final sheet = workbook[request.title];

    sheet.appendRow([TextCellValue(_schoolName)]);
    sheet.appendRow([TextCellValue(_schoolAddress)]);
    sheet.appendRow([TextCellValue(request.dateSheet.examName)]);
    sheet.appendRow([
      TextCellValue('Session'),
      TextCellValue(request.dateSheet.academicSession),
    ]);
    sheet.appendRow([TextCellValue(request.title)]);
    if (request.subject.trim().isNotEmpty) {
      sheet.appendRow([TextCellValue(request.subject)]);
    }
    sheet.appendRow([]);

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Day'),
      TextCellValue('Class'),
      TextCellValue('Section'),
      TextCellValue('Subject'),
      TextCellValue('Teacher'),
      TextCellValue('Time'),
      TextCellValue('Total Marks'),
      TextCellValue('Passing Marks'),
      TextCellValue('Instructions'),
    ]);

    for (final paper in request.papers) {
      sheet.appendRow([
        TextCellValue(_date(paper.examDate)),
        TextCellValue(_day(paper.examDate.weekday)),
        TextCellValue(paper.className),
        TextCellValue(paper.sectionName),
        TextCellValue(paper.subjectName),
        TextCellValue(paper.teacherName),
        TextCellValue(
          '${_time(paper.startMinutes)} - ${_time(paper.endMinutes)}',
        ),
        DoubleCellValue(paper.totalMarks),
        DoubleCellValue(paper.passingMarks),
        TextCellValue(paper.instructions),
      ]);
    }

    for (var index = 0; index <= 9; index++) {
      sheet.setColumnWidth(index, index == 9 ? 32 : 18);
    }

    workbook.delete('Sheet1');
    final encoded = workbook.encode();
    if (encoded == null) {
      throw StateError('Unable to create Excel report.');
    }

    Share.downloadFallbackEnabled = true;
    await Share.shareXFiles(
      [
        XFile.fromData(
          Uint8List.fromList(encoded),
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      fileNameOverrides: [
        '${_safeName(request.title)}_${_safeName(request.subject)}.xlsx',
      ],
      subject: request.title,
    );
  }

  Future<Uint8List> _buildPdf(ExamDateSheetReportRequest request) async {
    final document = pw.Document();
    final logo = await _loadLogo();
    final isParentCopy =
        request.type == ExamDateSheetReportType.parentClassCopy;
    final pageFormat = isParentCopy
        ? PdfPageFormat.a4
        : PdfPageFormat.a4.landscape;

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => _header(logo, request),
        footer: _footer,
        build: (_) => [
          if (request.papers.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Text('No papers are available for this report.'),
            )
          else if (isParentCopy)
            ..._parentCopy(request)
          else
            _reportTable(request),
          pw.SizedBox(height: 26),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.SizedBox(height: 22),
                  pw.Container(width: 130, height: 0.7, color: PdfColors.black),
                  pw.Text(
                    'Exam Coordinator',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.SizedBox(height: 22),
                  pw.Container(width: 130, height: 0.7, color: PdfColors.black),
                  pw.Text(
                    'Principal Signature',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header(
    pw.ImageProvider? logo,
    ExamDateSheetReportRequest request,
  ) {
    final watermark = request.dateSheet.status.name.toUpperCase();

    return pw.Column(
      children: [
        pw.Row(
          children: [
            if (logo != null)
              pw.Container(
                width: 48,
                height: 48,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            if (logo != null) pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _schoolName,
                    style: pw.TextStyle(
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _schoolAddress,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    request.title.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey500),
              ),
              child: pw.Text(
                watermark,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey700,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 7),
        pw.Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _meta('Exam', request.dateSheet.examName),
            _meta('Session', request.dateSheet.academicSession),
            if (request.subject.trim().isNotEmpty)
              _meta('For', request.subject),
            _meta('Issue Date', _date(DateTime.now())),
          ],
        ),
        pw.Divider(color: PdfColors.blueGrey300),
      ],
    );
  }

  pw.Widget _meta(String label, String value) {
    return pw.RichText(
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
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page ${context.pageNumber}/${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey700),
      ),
    );
  }

  List<pw.Widget> _parentCopy(ExamDateSheetReportRequest request) {
    return [
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: const [
          'Date',
          'Day',
          'Subject',
          'Time',
          'Total Marks',
          'Passing Marks',
        ],
        data: request.papers
            .map(
              (paper) => [
                _date(paper.examDate),
                _day(paper.examDate.weekday),
                paper.subjectName,
                '${_time(paper.startMinutes)} - ${_time(paper.endMinutes)}',
                paper.totalMarks.toStringAsFixed(0),
                paper.passingMarks.toStringAsFixed(0),
              ],
            )
            .toList(growable: false),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
        headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 8),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        border: pw.TableBorder.all(color: PdfColors.blueGrey300, width: 0.5),
      ),
      pw.SizedBox(height: 14),
      pw.Text(
        'General Instructions',
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 5),
      pw.Bullet(
        text: 'Students must arrive at least 20 minutes before the paper.',
      ),
      pw.Bullet(
        text: 'Bring the required stationery and school identification.',
      ),
      pw.Bullet(
        text: 'Late arrival will be handled according to school policy.',
      ),
    ];
  }

  pw.Widget _reportTable(ExamDateSheetReportRequest request) {
    final teacherDuty = request.type == ExamDateSheetReportType.teacherDuty;

    final headers = teacherDuty
        ? const ['Date', 'Day', 'Class', 'Section', 'Subject', 'Time']
        : const [
            'Date',
            'Day',
            'Class',
            'Section',
            'Subject',
            'Teacher',
            'Time',
            'Marks',
          ];

    final rows = request.papers
        .map(
          (paper) => teacherDuty
              ? [
                  _date(paper.examDate),
                  _day(paper.examDate.weekday),
                  paper.className,
                  paper.sectionName,
                  paper.subjectName,
                  '${_time(paper.startMinutes)} - ${_time(paper.endMinutes)}',
                ]
              : [
                  _date(paper.examDate),
                  _day(paper.examDate.weekday),
                  paper.className,
                  paper.sectionName,
                  paper.subjectName,
                  paper.teacherName,
                  '${_time(paper.startMinutes)} - ${_time(paper.endMinutes)}',
                  '${paper.totalMarks.toStringAsFixed(0)} / ${paper.passingMarks.toStringAsFixed(0)}',
                ],
        )
        .toList(growable: false);

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 6.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      border: pw.TableBorder.all(color: PdfColors.blueGrey300, width: 0.5),
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

  static String _safeName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? 'Date_Sheet' : cleaned;
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';

  static String _day(int weekday) => switch (weekday) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    DateTime.sunday => 'Sunday',
    _ => '',
  };

  static String _time(int value) {
    final hour = value ~/ 60;
    final minute = value % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }
}
