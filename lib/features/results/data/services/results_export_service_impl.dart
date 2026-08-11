import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../exams/domain/services/result_subject_grouping_service.dart';
import '../../domain/entities/result_export_request.dart';
import '../../domain/services/results_export_service.dart';

class ResultsExportServiceImpl implements ResultsExportService {
  static const _schoolName = 'Almustafa Model School';
  static const _schoolAddress = 'VIP Colony, Suraj Miani, Multan';

  @override
  Future<Uint8List> buildPdf(ResultExportRequest request) async {
    final document = pw.Document();
    final logo = await _loadLogo();
    final format = request.isPortrait
        ? PdfPageFormat.a4
        : PdfPageFormat.a4.landscape;
    if (request.isBulkReportCard) {
      for (final result in request.results) {
        document.addPage(
          pw.MultiPage(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(28),
            header: (_) => _header(logo, request, result: result),
            footer: _footer,
            build: (_) => _reportCardContent(request, result),
          ),
        );
      }
    } else {
      document.addPage(
        pw.MultiPage(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(28),
          header: (_) => _header(
            logo,
            request,
            result: request.isIndividualReportCard && request.results.isNotEmpty
                ? request.results.first
                : null,
          ),
          footer: _footer,
          build: (_) =>
              request.isIndividualReportCard && request.results.isNotEmpty
              ? _reportCardContent(request, request.results.first)
              : _tableReportContent(request),
        ),
      );
    }
    return document.save();
  }

  @override
  Future<Uint8List> buildExcel(ResultExportRequest request) async {
    final excel = Excel.createExcel();
    final summary = excel['Summary'];
    _appendMetadata(summary, request);
    _appendMetrics(summary, request.metrics);
    _appendResultsSheet(excel['Student Results'], request);
    _appendSubjectSheet(excel['Subject Analysis'], request);
    _appendGradeDistribution(excel['Grade Distribution'], request);
    _appendPassFailSheet(excel['Pass Fail Details'], request);
    excel.delete('Sheet1');
    final data = excel.encode();
    if (data == null) {
      throw StateError('Unable to create the Excel workbook.');
    }
    return Uint8List.fromList(data);
  }

  @override
  Future<void> exportPdf(ResultExportRequest request) async {
    final bytes = await buildPdf(request);
    await Printing.sharePdf(bytes: bytes, filename: fileName(request, 'pdf'));
  }

  @override
  Future<void> exportExcel(ResultExportRequest request) async {
    await _shareBytes(
      await buildExcel(request),
      fileName(request, 'xlsx'),
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      subject: request.title,
    );
  }

  @override
  Future<void> printPdf(ResultExportRequest request) async {
    final bytes = await buildPdf(request);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Future<void> sharePdf(ResultExportRequest request) async {
    await _shareBytes(
      await buildPdf(request),
      fileName(request, 'pdf'),
      'application/pdf',
      subject: request.title,
    );
  }

  @override
  Future<void> shareExcel(ResultExportRequest request) async {
    await _shareBytes(
      await buildExcel(request),
      fileName(request, 'xlsx'),
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      subject: request.title,
    );
  }

  @override
  String fileName(ResultExportRequest request, String extension) {
    final values =
        [
              request.title,
              request.filters['Exam'],
              request.filters['Class'],
              request.filters['Section'],
              request.filters['Academic Session'],
            ]
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .map(_safeFileSegment)
            .toList(growable: false);
    final base = values.isEmpty ? 'Result_Export' : values.join('_');
    return '$base.$extension';
  }

  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final bytes = await rootBundle.load('assets/images/logo.jpeg');
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  pw.Widget _header(
    pw.ImageProvider? logo,
    ResultExportRequest request, {
    required dynamic result,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logo != null)
              pw.Container(
                width: 44,
                height: 44,
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                  image: pw.DecorationImage(image: logo, fit: pw.BoxFit.cover),
                ),
              )
            else
              pw.Container(
                width: 44,
                height: 44,
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
                  pw.SizedBox(height: 2),
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
          ],
        ),
        pw.SizedBox(height: 8),
        _filtersTable(request.filters),
        pw.Divider(color: PdfColors.blueGrey300),
      ],
    );
  }

  pw.Widget _footer(pw.Context context) => pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Text(
      'Generated ${_dateTime(DateTime.now())}  |  Page ${context.pageNumber}/${context.pagesCount}',
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey700),
    ),
  );

  List<pw.Widget> _reportCardContent(
    ResultExportRequest request,
    dynamic result,
  ) {
    return [
      pw.SizedBox(height: 10),
      pw.Text(
        'Student: ${_value(result.studentName)}',
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          _pdfText('Roll No', _value(result.rollNumber)),
          _pdfText('Admission No', _value(result.admissionNo)),
          _pdfText('Class', _value(result.className)),
          _pdfText('Section', _value(result.sectionName)),
          _pdfText('Father Name', _value(request.student?.fatherName ?? '')),
        ],
      ),
      pw.SizedBox(height: 14),
      pw.TableHelper.fromTextArray(
        headers: const [
          'Subject',
          'Components',
          'Total',
          'Percentage',
          'Grade',
          'Status',
          'Remarks',
        ],
        data: ResultSubjectGroupingService.group(result.subjectResults)
            .map<List<dynamic>>(
              (subject) => [
                _value(subject.subjectName),
                subject.components
                    .map(
                      (component) => component.isAbsent
                          ? '${component.label}: Absent'
                          : '${component.label}: ${_number(component.obtainedMarks)} / ${_number(component.totalMarks)}',
                    )
                    .join(' | '),
                '${_number(subject.obtainedMarks)} / ${_number(subject.totalMarks)}',
                _percent(subject.percentage),
                subject.grade,
                subject.isPassed ? 'Pass' : 'Fail',
                _value(subject.remarks),
              ],
            )
            .toList(growable: false),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 8),
      ),
      pw.SizedBox(height: 14),
      pw.TableHelper.fromTextArray(
        headers: const [
          'Total',
          'Obtained',
          'Percentage',
          'Grade',
          'Position',
          'Result',
        ],
        data: [
          [
            _number(result.grandTotalMarks),
            _number(result.grandObtainedMarks),
            _percent(result.percentage),
            _value(result.grade),
            result.sectionPosition == 0 ? '-' : '${result.sectionPosition}',
            result.isPassed ? 'Pass' : 'Fail',
          ],
        ],
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
      if (request.attendancePercentage != null) ...[
        pw.SizedBox(height: 10),
        pw.Text(
          'Attendance Percentage: ${_percent(request.attendancePercentage!)}',
        ),
      ],
      pw.SizedBox(height: 12),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _signature('Class Teacher'),
          _signature('Parent / Guardian'),
          _signature('Principal'),
        ],
      ),
    ];
  }

  List<pw.Widget> _tableReportContent(ResultExportRequest request) {
    final results = request.results;
    final passed = results.where((result) => result.isPassed).length;
    final total = results.length;
    final metrics = request.metrics.isEmpty
        ? [
            ResultExportMetric(label: 'Total Students', value: '$total'),
            ResultExportMetric(label: 'Passed', value: '$passed'),
            ResultExportMetric(label: 'Failed', value: '${total - passed}'),
            ResultExportMetric(
              label: 'Pass Percentage',
              value: _percent(total == 0 ? 0 : (passed / total) * 100),
            ),
          ]
        : request.metrics;
    return [
      pw.SizedBox(height: 10),
      _metricsTable(metrics),
      pw.SizedBox(height: 14),
      pw.TableHelper.fromTextArray(
        headers: const [
          'Roll No',
          'Admission No',
          'Student',
          'Class',
          'Section',
          'Total',
          'Obtained',
          '%',
          'Grade',
          'Position',
          'Result',
        ],
        data: results
            .map(
              (result) => [
                _value(result.rollNumber),
                _value(result.admissionNo),
                _value(result.studentName),
                _value(result.className),
                _value(result.sectionName),
                _number(result.grandTotalMarks),
                _number(result.grandObtainedMarks),
                _percent(result.percentage),
                _value(result.grade),
                result.sectionPosition == 0 ? '-' : '${result.sectionPosition}',
                result.isPassed ? 'Pass' : 'Fail',
              ],
            )
            .toList(growable: false),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
        cellStyle: const pw.TextStyle(fontSize: 6.5),
        cellAlignment: pw.Alignment.centerLeft,
      ),
    ];
  }

  pw.Widget _filtersTable(Map<String, String> filters) {
    final entries = filters.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .toList(growable: false);
    if (entries.isEmpty) {
      return pw.SizedBox();
    }
    return pw.Wrap(
      spacing: 12,
      runSpacing: 3,
      children: entries
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
    );
  }

  pw.Widget _metricsTable(List<ResultExportMetric> metrics) =>
      pw.TableHelper.fromTextArray(
        headers: metrics.map((metric) => metric.label).toList(growable: false),
        data: [metrics.map((metric) => metric.value).toList(growable: false)],
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
        cellStyle: const pw.TextStyle(fontSize: 8),
      );

  pw.Widget _pdfText(String label, String value) => pw.RichText(
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

  pw.Widget _signature(String label) => pw.Container(
    width: 130,
    padding: const pw.EdgeInsets.only(top: 24),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: PdfColors.black)),
    ),
    child: pw.Center(
      child: pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
    ),
  );

  Future<void> _shareBytes(
    Uint8List bytes,
    String name,
    String mimeType, {
    required String subject,
  }) async {
    Share.downloadFallbackEnabled = true;
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: mimeType)],
      fileNameOverrides: [name],
      subject: subject,
    );
  }

  void _appendMetadata(Sheet sheet, ResultExportRequest request) {
    sheet.appendRow([TextCellValue(_schoolName)]);
    sheet.appendRow([TextCellValue(_schoolAddress)]);
    sheet.appendRow([TextCellValue(request.title)]);
    for (final entry in request.filters.entries) {
      if (entry.value.trim().isNotEmpty) {
        sheet.appendRow([TextCellValue(entry.key), TextCellValue(entry.value)]);
      }
    }
    sheet.appendRow([]);
    _setSheetWidth(sheet, 0, 24);
    _setSheetWidth(sheet, 1, 28);
  }

  void _appendMetrics(Sheet sheet, List<ResultExportMetric> metrics) {
    if (metrics.isEmpty) return;
    final row = sheet.maxRows;
    sheet.appendRow(
      metrics.map((metric) => TextCellValue(metric.label)).toList(),
    );
    sheet.appendRow(
      metrics.map((metric) => TextCellValue(metric.value)).toList(),
    );
    _styleHeader(sheet, row);
  }

  void _appendResultsSheet(Sheet sheet, ResultExportRequest request) {
    _appendMetadata(sheet, request);
    final headerRow = sheet.maxRows;
    sheet.appendRow([
      TextCellValue('Roll No'),
      TextCellValue('Admission No'),
      TextCellValue('Student Name'),
      TextCellValue('Class'),
      TextCellValue('Section'),
      TextCellValue('Total Marks'),
      TextCellValue('Obtained Marks'),
      TextCellValue('Percentage'),
      TextCellValue('Grade'),
      TextCellValue('Position'),
      TextCellValue('Pass / Fail'),
    ]);
    for (final result in request.results) {
      sheet.appendRow([
        TextCellValue(_value(result.rollNumber)),
        TextCellValue(_value(result.admissionNo)),
        TextCellValue(_value(result.studentName)),
        TextCellValue(_value(result.className)),
        TextCellValue(_value(result.sectionName)),
        DoubleCellValue(result.grandTotalMarks),
        DoubleCellValue(result.grandObtainedMarks),
        DoubleCellValue(result.percentage / 100),
        TextCellValue(_value(result.grade)),
        IntCellValue(result.sectionPosition),
        TextCellValue(result.isPassed ? 'Pass' : 'Fail'),
      ]);
    }
    _styleHeader(sheet, headerRow);
    for (var index = 0; index < 11; index++) {
      _setSheetWidth(sheet, index, index == 2 ? 28 : 16);
    }
  }

  void _appendSubjectSheet(Sheet sheet, ResultExportRequest request) {
    _appendMetadata(sheet, request);
    final headerRow = sheet.maxRows;
    sheet.appendRow([
      TextCellValue('Student'),
      TextCellValue('Subject'),
      TextCellValue('Components'),
      TextCellValue('Total'),
      TextCellValue('Percentage'),
      TextCellValue('Grade'),
      TextCellValue('Status'),
      TextCellValue('Remarks'),
    ]);
    for (final result in request.results) {
      for (final subject in ResultSubjectGroupingService.group(
        result.subjectResults,
      )) {
        if (request.subjectName != null &&
            !_sameText(subject.subjectName, request.subjectName!)) {
          continue;
        }
        sheet.appendRow([
          TextCellValue(_value(result.studentName)),
          TextCellValue(_value(subject.subjectName)),
          TextCellValue(
            subject.components
                .map(
                  (component) => component.isAbsent
                      ? '${component.label}: Absent'
                      : '${component.label}: ${_number(component.obtainedMarks)} / ${_number(component.totalMarks)}',
                )
                .join(' | '),
          ),
          TextCellValue(
            '${_number(subject.obtainedMarks)} / ${_number(subject.totalMarks)}',
          ),
          DoubleCellValue(subject.percentage / 100),
          TextCellValue(subject.grade),
          TextCellValue(subject.isPassed ? 'Pass' : 'Fail'),
          TextCellValue(_value(subject.remarks)),
        ]);
      }
    }
    _styleHeader(sheet, headerRow);
    for (var index = 0; index < 8; index++) {
      _setSheetWidth(
        sheet,
        index,
        index == 0 || index == 2 || index == 7 ? 28 : 16,
      );
    }
  }

  void _appendGradeDistribution(Sheet sheet, ResultExportRequest request) {
    _appendMetadata(sheet, request);
    final counts = <String, int>{};
    for (final result in request.results) {
      final grade = result.grade.trim().isEmpty ? 'N/A' : result.grade;
      counts[grade] = (counts[grade] ?? 0) + 1;
    }
    final headerRow = sheet.maxRows;
    sheet.appendRow([TextCellValue('Grade'), TextCellValue('Students')]);
    final grades = counts.keys.toList()..sort();
    for (final grade in grades) {
      sheet.appendRow([TextCellValue(grade), IntCellValue(counts[grade] ?? 0)]);
    }
    _styleHeader(sheet, headerRow);
    _setSheetWidth(sheet, 0, 18);
    _setSheetWidth(sheet, 1, 14);
  }

  void _appendPassFailSheet(Sheet sheet, ResultExportRequest request) {
    _appendMetadata(sheet, request);
    final headerRow = sheet.maxRows;
    sheet.appendRow([
      TextCellValue('Student'),
      TextCellValue('Percentage'),
      TextCellValue('Grade'),
      TextCellValue('Status'),
      TextCellValue('Failed Subjects'),
      TextCellValue('Absent Subjects'),
    ]);
    for (final result in request.results) {
      sheet.appendRow([
        TextCellValue(_value(result.studentName)),
        DoubleCellValue(result.percentage / 100),
        TextCellValue(_value(result.grade)),
        TextCellValue(result.isPassed ? 'Pass' : 'Fail'),
        IntCellValue(
          ResultSubjectGroupingService.group(
            result.subjectResults,
          ).where((subject) => !subject.isPassed).length,
        ),
        IntCellValue(
          ResultSubjectGroupingService.group(
            result.subjectResults,
          ).where((subject) => subject.isAbsent).length,
        ),
      ]);
    }
    _styleHeader(sheet, headerRow);
    for (var index = 0; index < 6; index++) {
      _setSheetWidth(sheet, index, index == 0 ? 28 : 18);
    }
  }

  void _styleHeader(Sheet sheet, int row) {
    final style = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('D9E2F3'),
    );
    for (var column = 0; column < sheet.maxColumns; column++) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
              )
              .cellStyle =
          style;
    }
  }

  void _setSheetWidth(Sheet sheet, int column, double width) {
    sheet.setColumnWidth(column, width);
  }
}

String _safeFileSegment(String value) {
  final trimmed = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  final compact = trimmed.replaceAll(RegExp(r'\s+'), '_');
  return compact.isEmpty ? 'Result' : compact;
}

bool _sameText(String first, String second) =>
    first.trim().toLowerCase() == second.trim().toLowerCase();

String _value(String value) => value.trim().isEmpty ? '-' : value.trim();

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String _percent(double value) => '${value.toStringAsFixed(1)}%';

String _dateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
