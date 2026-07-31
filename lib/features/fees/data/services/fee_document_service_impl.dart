import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/fee_document_request_entity.dart';
import '../../domain/entities/fee_payment_entity.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../../domain/services/fee_document_service.dart';

class FeeDocumentServiceImpl implements FeeDocumentService {
  static const _schoolName = 'Almustafa Model School';
  static const _schoolAddress = 'VIP Colony, Suraj Miani, Multan';

  @override
  Future<void> printChallan(FeeChallanDocumentRequest request) async {
    final bytes = await _buildChallanPdf(request);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Future<void> shareChallan(FeeChallanDocumentRequest request) async {
    final bytes = await _buildChallanPdf(request);
    final first = request.dues.first;
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'Fee_Challan_${_safe(first.studentName)}_${first.month}_${first.year}.pdf',
    );
  }

  @override
  Future<void> printReceipt(FeeReceiptDocumentRequest request) async {
    final bytes = await _buildReceiptPdf(request);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Future<void> shareReceipt(FeeReceiptDocumentRequest request) async {
    final bytes = await _buildReceiptPdf(request);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${request.payment.receiptNumber}.pdf',
    );
  }

  Future<Uint8List> _buildChallanPdf(FeeChallanDocumentRequest request) async {
    if (request.dues.isEmpty) {
      throw StateError('No fee dues selected for challan printing.');
    }

    final document = pw.Document();
    final logo = await _loadLogo();
    final grouped = <String, List<MonthlyFeeDueEntity>>{};

    for (final due in request.dues) {
      grouped.putIfAbsent(due.studentId, () => []).add(due);
    }

    for (final studentDues in grouped.values) {
      studentDues.sort((a, b) {
        final year = a.year.compareTo(b.year);
        if (year != 0) return year;
        return a.month.compareTo(b.month);
      });

      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(18),
          build: (_) {
            final copies = request.copyCount.clamp(1, 3);
            return pw.Column(
              children: [
                for (var index = 0; index < copies; index++) ...[
                  pw.Expanded(
                    child: _challanCopy(
                      studentDues,
                      logo,
                      _copyTitle(index, copies),
                    ),
                  ),
                  if (index < copies - 1)
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Container(
                              height: 0.5,
                              color: PdfColors.grey500,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            child: pw.Text(
                              'CUT HERE',
                              style: const pw.TextStyle(
                                fontSize: 6,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Container(
                              height: 0.5,
                              color: PdfColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      );
    }

    return document.save();
  }

  pw.Widget _challanCopy(
    List<MonthlyFeeDueEntity> dues,
    pw.ImageProvider? logo,
    String copyTitle,
  ) {
    final first = dues.first;
    final totalPayable = dues.fold<double>(
      0,
      (sum, item) => sum + item.outstandingAmount,
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey400, width: 0.8),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              if (logo != null)
                pw.Container(width: 38, height: 38, child: pw.Image(logo)),
              if (logo != null) pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _schoolName,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _schoolAddress,
                      style: const pw.TextStyle(fontSize: 6.5),
                    ),
                    pw.Text(
                      'FEE CHALLAN',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blueGrey400),
                ),
                child: pw.Text(
                  copyTitle,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 7),
          pw.Wrap(
            spacing: 14,
            runSpacing: 3,
            children: [
              _meta('Student', first.studentName),
              _meta('Admission No.', first.admissionNo),
              _meta('Session', first.academicSession),
              _meta('Due Date', _date(first.dueDate)),
            ],
          ),
          pw.SizedBox(height: 7),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Month',
              'Tuition',
              'Transport',
              'Other',
              'Discounts',
              'Arrears',
              'Paid',
              'Outstanding',
            ],
            data: dues
                .map(
                  (due) => [
                    '${_monthName(due.month)} ${due.year}',
                    _money(due.tuitionFee),
                    _money(due.transportFee),
                    _money(due.otherMonthlyCharges),
                    _money(due.totalDeductions),
                    _money(due.previousArrears),
                    _money(due.paidAmount),
                    _money(due.outstandingAmount),
                  ],
                )
                .toList(growable: false),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey100,
            ),
            headerStyle: pw.TextStyle(
              fontSize: 6.5,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 6.2),
            cellPadding: const pw.EdgeInsets.all(3.5),
            border: pw.TableBorder.all(
              color: PdfColors.blueGrey300,
              width: 0.4,
            ),
          ),
          pw.Spacer(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Payable: ${_money(totalPayable)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Column(
                children: [
                  pw.SizedBox(height: 10),
                  pw.Container(width: 95, height: 0.5, color: PdfColors.black),
                  pw.Text(
                    'Cashier Signature',
                    style: const pw.TextStyle(fontSize: 6),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _buildReceiptPdf(FeeReceiptDocumentRequest request) async {
    final payment = request.payment;
    final document = pw.Document();
    final logo = await _loadLogo();

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(22),
        build: (_) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blueGrey400, width: 0.8),
          ),
          padding: const pw.EdgeInsets.all(14),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  if (logo != null)
                    pw.Container(width: 44, height: 44, child: pw.Image(logo)),
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
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'FEE RECEIPT',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Divider(),
              _receiptRow('Receipt No.', payment.receiptNumber),
              _receiptRow('Student', payment.studentName),
              _receiptRow('Admission No.', payment.admissionNo),
              _receiptRow('Payment Date', _date(payment.paymentDate)),
              _receiptRow('Payment Method', _methodLabel(payment.method)),
              if (payment.referenceNumber.trim().isNotEmpty)
                _receiptRow('Reference No.', payment.referenceNumber),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: const ['Fee Month', 'Allocated Amount'],
                data: payment.allocations
                    .map(
                      (item) => [
                        '${_monthName(item.month)} ${item.year}',
                        _money(item.amount),
                      ],
                    )
                    .toList(growable: false),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey100,
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                border: pw.TableBorder.all(
                  color: PdfColors.blueGrey300,
                  width: 0.5,
                ),
              ),
              pw.SizedBox(height: 12),
              _receiptRow(
                'Allocated',
                _money(payment.allocatedAmount),
                bold: true,
              ),
              _receiptRow('Advance', _money(payment.advanceAmount)),
              _receiptRow(
                'Total Received',
                _money(payment.totalPaid),
                bold: true,
              ),
              if (payment.notes.trim().isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Notes: ${payment.notes}',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 100,
                        height: 0.5,
                        color: PdfColors.black,
                      ),
                      pw.Text(
                        'Parent Signature',
                        style: const pw.TextStyle(fontSize: 6.5),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 100,
                        height: 0.5,
                        color: PdfColors.black,
                      ),
                      pw.Text(
                        'Cashier Signature',
                        style: const pw.TextStyle(fontSize: 6.5),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return document.save();
  }

  pw.Widget _meta(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
          ),
          pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 7)),
        ],
      ),
    );
  }

  pw.Widget _receiptRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 105,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
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

  static String _copyTitle(int index, int copies) {
    if (copies == 1) return 'SCHOOL COPY';
    if (copies == 2) {
      return index == 0 ? 'SCHOOL COPY' : 'PARENT COPY';
    }
    return switch (index) {
      0 => 'SCHOOL COPY',
      1 => 'PARENT COPY',
      _ => 'BANK COPY',
    };
  }

  static String _safe(String value) => value
      .trim()
      .replaceAll(RegExp(r'[<>:"/\\|?*]+'), '_')
      .replaceAll(RegExp(r'\s+'), '_');

  static String _money(double value) => 'Rs. ${value.toStringAsFixed(0)}';

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';

  static String _monthName(int month) => const [
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

  static String _methodLabel(FeePaymentMethod method) => switch (method) {
    FeePaymentMethod.cash => 'Cash',
    FeePaymentMethod.bankTransfer => 'Bank Transfer',
    FeePaymentMethod.easypaisa => 'Easypaisa',
    FeePaymentMethod.jazzCash => 'JazzCash',
  };
}
