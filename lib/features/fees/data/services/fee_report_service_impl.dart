import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/fee_payment_entity.dart';
import '../../domain/entities/fee_report_entity.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../../domain/services/fee_report_service.dart';

class FeeReportServiceImpl implements FeeReportService {
  static const _schoolName = 'Almustafa Model School';
  static const _schoolAddress = 'VIP Colony, Suraj Miani, Multan';

  @override
  Future<void> printPdf(FeeReportData report) async {
    final bytes = await _buildPdf(report);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Future<void> sharePdf(FeeReportData report) async {
    final bytes = await _buildPdf(report);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_title(report.type).replaceAll(' ', '_')}.pdf',
    );
  }

  @override
  Future<void> exportExcel(FeeReportData report) async {
    final workbook = Excel.createExcel();
    final sheet = workbook[_title(report.type)];

    sheet.appendRow([TextCellValue(_schoolName)]);
    sheet.appendRow([TextCellValue(_schoolAddress)]);
    sheet.appendRow([TextCellValue(_title(report.type))]);
    sheet.appendRow([
      TextCellValue('Period'),
      TextCellValue('${_date(report.startDate)} - ${_date(report.endDate)}'),
    ]);
    sheet.appendRow([]);

    if (report.type == FeeReportType.collectionSummary ||
        report.type == FeeReportType.paymentMethods) {
      sheet.appendRow([
        TextCellValue('Receipt'),
        TextCellValue('Date'),
        TextCellValue('Student'),
        TextCellValue('Admission No.'),
        TextCellValue('Method'),
        TextCellValue('Amount'),
        TextCellValue('Advance'),
        TextCellValue('Status'),
      ]);

      for (final payment in report.payments) {
        sheet.appendRow([
          TextCellValue(payment.receiptNumber),
          TextCellValue(_date(payment.paymentDate)),
          TextCellValue(payment.studentName),
          TextCellValue(payment.admissionNo),
          TextCellValue(_method(payment.method)),
          DoubleCellValue(payment.totalPaid),
          DoubleCellValue(payment.advanceAmount),
          TextCellValue(payment.status.name),
        ]);
      }
    } else {
      sheet.appendRow([
        TextCellValue('Student'),
        TextCellValue('Admission No.'),
        TextCellValue('Month'),
        TextCellValue('Demand'),
        TextCellValue('Paid'),
        TextCellValue('Outstanding'),
        TextCellValue('Discounts'),
        TextCellValue('Arrears'),
        TextCellValue('Status'),
      ]);

      for (final due in _filteredDues(report)) {
        sheet.appendRow([
          TextCellValue(due.studentName),
          TextCellValue(due.admissionNo),
          TextCellValue('${_month(due.month)} ${due.year}'),
          DoubleCellValue(due.netPayable),
          DoubleCellValue(due.paidAmount),
          DoubleCellValue(due.outstandingAmount),
          DoubleCellValue(due.totalDeductions),
          DoubleCellValue(due.previousArrears),
          TextCellValue(due.status.name),
        ]);
      }
    }

    for (var index = 0; index < 9; index++) {
      sheet.setColumnWidth(index, index <= 2 ? 22 : 16);
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
      fileNameOverrides: ['${_title(report.type).replaceAll(' ', '_')}.xlsx'],
      subject: _title(report.type),
    );
  }

  Future<Uint8List> _buildPdf(FeeReportData report) async {
    final document = pw.Document();
    final logo = await _loadLogo();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => _header(report, logo),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7),
          ),
        ),
        build: (_) => [
          _summary(report),
          pw.SizedBox(height: 12),
          if (report.type == FeeReportType.collectionSummary ||
              report.type == FeeReportType.paymentMethods)
            _paymentsTable(report)
          else
            _duesTable(report),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header(FeeReportData report, pw.ImageProvider? logo) {
    return pw.Column(
      children: [
        pw.Row(
          children: [
            if (logo != null)
              pw.Container(width: 42, height: 42, child: pw.Image(logo)),
            if (logo != null) pw.SizedBox(width: 10),
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
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                  pw.Text(
                    _title(report.type),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.Text(
              '${_date(report.startDate)} - ${_date(report.endDate)}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _summary(FeeReportData report) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _metric('Demand', report.totalDemand),
        _metric('Collected', report.totalCollected),
        _metric('Outstanding', report.totalOutstanding),
        _metric('Discounts', report.totalDiscounts),
        _metric('Arrears', report.totalArrears),
        _metric('Advance', report.totalAdvance),
      ],
    );
  }

  pw.Widget _metric(String label, double value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey300),
      ),
      child: pw.Text(
        '$label: Rs. ${value.toStringAsFixed(0)}',
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _paymentsTable(FeeReportData report) {
    return pw.TableHelper.fromTextArray(
      headers: const [
        'Receipt',
        'Date',
        'Student',
        'Admission No.',
        'Method',
        'Paid',
        'Advance',
        'Status',
      ],
      data: report.payments
          .map(
            (payment) => [
              payment.receiptNumber,
              _date(payment.paymentDate),
              payment.studentName,
              payment.admissionNo,
              _method(payment.method),
              payment.totalPaid.toStringAsFixed(0),
              payment.advanceAmount.toStringAsFixed(0),
              payment.status.name,
            ],
          )
          .toList(growable: false),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 6.5),
      border: pw.TableBorder.all(color: PdfColors.blueGrey300, width: 0.4),
    );
  }

  pw.Widget _duesTable(FeeReportData report) {
    return pw.TableHelper.fromTextArray(
      headers: const [
        'Student',
        'Admission No.',
        'Month',
        'Demand',
        'Paid',
        'Outstanding',
        'Discounts',
        'Arrears',
        'Status',
      ],
      data: _filteredDues(report)
          .map(
            (due) => [
              due.studentName,
              due.admissionNo,
              '${_month(due.month)} ${due.year}',
              due.netPayable.toStringAsFixed(0),
              due.paidAmount.toStringAsFixed(0),
              due.outstandingAmount.toStringAsFixed(0),
              due.totalDeductions.toStringAsFixed(0),
              due.previousArrears.toStringAsFixed(0),
              due.status.name,
            ],
          )
          .toList(growable: false),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 6.5),
      border: pw.TableBorder.all(color: PdfColors.blueGrey300, width: 0.4),
    );
  }

  List<MonthlyFeeDueEntity> _filteredDues(FeeReportData report) {
    return switch (report.type) {
      FeeReportType.outstanding =>
        report.dues
            .where((item) => item.outstandingAmount > 0)
            .toList(growable: false),
      FeeReportType.defaulters =>
        report.dues
            .where(
              (item) =>
                  item.outstandingAmount > 0 &&
                  item.dueDate.isBefore(DateTime.now()),
            )
            .toList(growable: false),
      FeeReportType.discounts =>
        report.dues
            .where((item) => item.totalDeductions > 0)
            .toList(growable: false),
      _ => report.dues,
    };
  }

  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/images/logo.jpeg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _title(FeeReportType type) => switch (type) {
    FeeReportType.collectionSummary => 'Collection Summary',
    FeeReportType.outstanding => 'Outstanding Fee Report',
    FeeReportType.defaulters => 'Defaulters Report',
    FeeReportType.discounts => 'Discounts and Scholarships Report',
    FeeReportType.paymentMethods => 'Payment Method Report',
    FeeReportType.demandVsCollection => 'Demand vs Collection Report',
  };

  static String _method(FeePaymentMethod method) => switch (method) {
    FeePaymentMethod.cash => 'Cash',
    FeePaymentMethod.bankTransfer => 'Bank Transfer',
    FeePaymentMethod.easypaisa => 'Easypaisa',
    FeePaymentMethod.jazzCash => 'JazzCash',
  };

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';

  static String _month(int month) => const [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month];
}
