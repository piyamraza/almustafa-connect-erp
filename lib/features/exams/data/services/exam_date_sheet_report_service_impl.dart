import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_class_order.dart';
import '../../domain/entities/exam_date_sheet_entity.dart';
import '../../domain/entities/exam_date_sheet_report_entity.dart';
import '../../domain/services/exam_date_sheet_report_service.dart';

class ExamDateSheetReportServiceImpl implements ExamDateSheetReportService {
  ExamDateSheetReportServiceImpl(this._academicStructureRepository);

  final AcademicStructureRepository _academicStructureRepository;

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
  Future<void> downloadAllClassesPdf(
    ExamDateSheetReportRequest request,
  ) async {
    if (!request.type.isClassCopy) {
      throw StateError('Select a class date sheet report type first.');
    }
    final bytes = await _buildAllClassesPdf(request);
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          '${_safeName(request.dateSheet.examName)}_All_Class_Date_Sheets.pdf',
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

    final isClassCopy = request.type.isClassCopy;
    if (!isClassCopy) {
      final columns = await _loadMatrixColumns(request);
      _writeMatrixExcel(sheet, request, columns);
    } else {
      final showsMarks = request.type.showsMarks;
      sheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Day'),
        TextCellValue('Class'),
        TextCellValue('Section'),
        TextCellValue('Subject'),
        TextCellValue('Time'),
        if (showsMarks) TextCellValue('Total Marks'),
        if (showsMarks) TextCellValue('Passing Marks'),
        TextCellValue('Instructions'),
      ]);
      for (final paper in request.papers) {
        sheet.appendRow([
          TextCellValue(_date(paper.examDate)),
          TextCellValue(_day(paper.examDate.weekday)),
          TextCellValue(paper.className),
          TextCellValue(paper.sectionName),
          TextCellValue(paper.subjectName),
          TextCellValue(
            '${_time(paper.startMinutes)} - ${_time(paper.endMinutes)}',
          ),
          if (showsMarks) DoubleCellValue(paper.totalMarks),
          if (showsMarks) DoubleCellValue(paper.passingMarks),
          TextCellValue(paper.instructions),
        ]);
      }
      final lastColumn = showsMarks ? 8 : 6;
      for (var index = 0; index <= lastColumn; index++) {
        sheet.setColumnWidth(index, index == lastColumn ? 32 : 18);
      }
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

  void _writeMatrixExcel(
    Sheet sheet,
    ExamDateSheetReportRequest request,
    List<_ReportMatrixColumn> orderedColumns,
  ) {
    final teacherDuty = request.type == ExamDateSheetReportType.teacherDuty;
    final dates = request.papers.map((paper) => paper.examDate).toSet().toList()
      ..sort();
    sheet.appendRow([
      TextCellValue('Date'),
      ...orderedColumns.map((column) => TextCellValue(column.label)),
    ]);
    for (final date in dates) {
      final cells = <CellValue>[
        TextCellValue('${_date(date)}\n${_day(date.weekday)}'),
      ];
      for (final column in orderedColumns) {
        final papers = request.papers.where((paper) {
          final sameDate =
              paper.examDate.year == date.year &&
              paper.examDate.month == date.month &&
              paper.examDate.day == date.day;
          final sameColumn = teacherDuty
              ? paper.teacherId == column.key
              : '${paper.classId}|${paper.sectionId}' == column.key;
          return sameDate && sameColumn;
        });
        cells.add(
          TextCellValue(
            papers.isEmpty
                ? '-'
                : papers
                      .map(
                        (paper) => teacherDuty
                            ? '${paper.className}-${paper.sectionName} '
                                  '${paper.subjectName}\n'
                                  '${_time(paper.startMinutes)}-${_time(paper.endMinutes)}'
                            : paper.subjectName,
                      )
                      .join('\n'),
          ),
        );
      }
      sheet.appendRow(cells);
    }
    for (var index = 0; index <= orderedColumns.length; index++) {
      sheet.setColumnWidth(index, index == 0 ? 18 : 24);
    }
  }

  Future<Uint8List> _buildPdf(ExamDateSheetReportRequest request) async {
    final document = pw.Document();
    final logo = await _loadLogo();
    final isClassCopy = request.type.isClassCopy;
    final pageFormat = isClassCopy
        ? PdfPageFormat.a4
        : PdfPageFormat.a4.landscape;
    final matrixColumns = isClassCopy
        ? const <_ReportMatrixColumn>[]
        : await _loadMatrixColumns(request);

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(isClassCopy ? 28 : 18),
        header: (_) => _header(logo, request),
        footer: _footer,
        build: (_) => [
          if (request.papers.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Text('No papers are available for this report.'),
            )
          else if (isClassCopy)
            ..._classCopy(request)
          else
            _reportTable(request, matrixColumns),
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

  Future<Uint8List> _buildAllClassesPdf(
    ExamDateSheetReportRequest request,
  ) async {
    final document = pw.Document();
    final logo = await _loadLogo();
    final classSections = <String, ExamDateSheetPaperEntity>{};
    for (final paper in request.dateSheet.papers) {
      classSections['${paper.classId}|${paper.sectionId}'] = paper;
    }
    final ordered = classSections.values.toList()
      ..sort((first, second) {
        final classOrder = compareAcademicClassNames(
          first.className,
          second.className,
        );
        return classOrder != 0
            ? classOrder
            : first.sectionName.compareTo(second.sectionName);
      });
    if (ordered.isEmpty) {
      throw StateError('No class date sheets are available to download.');
    }

    for (final item in ordered) {
      final classRequest = ExamDateSheetReportRequest(
        dateSheet: request.dateSheet,
        type: request.type,
        classId: item.classId,
        className: item.className,
        sectionId: item.sectionId,
        sectionName: item.sectionName,
      );
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (_) => _header(logo, classRequest),
          footer: _footer,
          build: (_) => [
            ..._classCopy(classRequest),
            pw.SizedBox(height: 26),
            _signatureRow(),
          ],
        ),
      );
    }
    return document.save();
  }

  pw.Widget _signatureRow() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        for (final label in ['Exam Coordinator', 'Principal Signature'])
          pw.Column(
            children: [
              pw.SizedBox(height: 22),
              pw.Container(width: 130, height: 0.7, color: PdfColors.black),
              pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
      ],
    );
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
            if (request.type != ExamDateSheetReportType.completeSchool &&
                request.subject.trim().isNotEmpty)
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

  List<pw.Widget> _classCopy(ExamDateSheetReportRequest request) {
    final showsMarks = request.type.showsMarks;
    return [
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: [
          'Date',
          'Day',
          'Subject',
          'Time',
          if (showsMarks) 'Total Marks',
          if (showsMarks) 'Passing Marks',
        ],
        data: request.papers
            .map(
              (paper) => [
                _date(paper.examDate),
                _day(paper.examDate.weekday),
                paper.subjectName,
                '${_time(paper.startMinutes)} - ${_time(paper.endMinutes)}',
                if (showsMarks) paper.totalMarks.toStringAsFixed(0),
                if (showsMarks) paper.passingMarks.toStringAsFixed(0),
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

  pw.Widget _reportTable(
    ExamDateSheetReportRequest request,
    List<_ReportMatrixColumn> orderedColumns,
  ) {
    final teacherDuty = request.type == ExamDateSheetReportType.teacherDuty;
    final dates = request.papers.map((paper) => paper.examDate).toSet().toList()
      ..sort();
    final headers = ['Date', ...orderedColumns.map((column) => column.label)];
    final rows = dates.map((date) {
      final row = <String>['${_date(date)}\n${_day(date.weekday)}'];
      for (final column in orderedColumns) {
        final papers = request.papers.where((paper) {
          final sameDate =
              paper.examDate.year == date.year &&
              paper.examDate.month == date.month &&
              paper.examDate.day == date.day;
          final sameColumn = teacherDuty
              ? paper.teacherId == column.key
              : '${paper.classId}|${paper.sectionId}' == column.key;
          return sameDate && sameColumn;
        });
        row.add(
          papers.isEmpty
              ? '-'
              : papers
                    .map(
                      (paper) => teacherDuty
                          ? '${paper.className}-${paper.sectionName} '
                                '${paper.subjectName}\n'
                                '${_time(paper.startMinutes)}-${_time(paper.endMinutes)}'
                          : paper.subjectName,
                    )
                    .join('\n'),
        );
      }
      return row;
    }).toList();
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(0.82),
      for (var index = 1; index <= orderedColumns.length; index++)
        index: const pw.FlexColumnWidth(1),
    };

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      headerStyle: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      cellAlignments: const {0: pw.Alignment.center},
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      textStyleBuilder: (index, _, _) => index == 0
          ? pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)
          : const pw.TextStyle(fontSize: 7.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2.5, vertical: 4),
      columnWidths: columnWidths,
      border: pw.TableBorder.all(color: PdfColors.blueGrey300, width: 0.5),
    );
  }

  Future<List<_ReportMatrixColumn>> _loadMatrixColumns(
    ExamDateSheetReportRequest request,
  ) async {
    final teacherDuty = request.type == ExamDateSheetReportType.teacherDuty;
    final columns = <String, _ReportMatrixColumn>{};
    for (final paper in request.papers) {
      final key = teacherDuty
          ? paper.teacherId
          : '${paper.classId}|${paper.sectionId}';
      columns[key] = _ReportMatrixColumn(
        key: key,
        label: teacherDuty
            ? paper.teacherName
            : 'Class ${paper.className}-${paper.sectionName}',
        className: paper.className,
        sectionName: paper.sectionName,
      );
    }

    if (request.type == ExamDateSheetReportType.completeSchool) {
      final classes =
          (await _academicStructureRepository.getClasses())
              .where((item) => item.isActive)
              .toList()
            ..sort(compareAcademicClasses);
      final sections = (await _academicStructureRepository.getSections())
          .where((item) => item.isActive)
          .toList();
      for (final academicClass in classes) {
        final classSections =
            sections
                .where((section) => section.classId == academicClass.id)
                .toList()
              ..sort((first, second) => first.name.compareTo(second.name));
        for (final section in classSections) {
          final key = '${academicClass.id}|${section.id}';
          columns[key] = _ReportMatrixColumn(
            key: key,
            label: 'Class ${academicClass.name}-${section.name}',
            className: academicClass.name,
            sectionName: section.name,
          );
        }
      }
    }

    final values = columns.values.toList()
      ..sort((first, second) {
        if (teacherDuty) return first.label.compareTo(second.label);
        final classOrder = compareAcademicClassNames(
          first.className,
          second.className,
        );
        return classOrder != 0
            ? classOrder
            : first.sectionName.compareTo(second.sectionName);
      });
    return values;
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

class _ReportMatrixColumn {
  const _ReportMatrixColumn({
    required this.key,
    required this.label,
    required this.className,
    required this.sectionName,
  });

  final String key;
  final String label;
  final String className;
  final String sectionName;
}
