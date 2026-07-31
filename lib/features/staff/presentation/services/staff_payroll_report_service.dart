import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/staff_salary_entity.dart';

class StaffPayrollReportService {
  const StaffPayrollReportService._();

  static Future<Uint8List> buildSalarySlipPdf({
    required StaffSalaryEntity salary,
    required PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document(
      title:
          'Salary Slip - ${salary.staffName} - ${_monthLabel(salary.salaryMonth)}',
      author: 'Almustafa Connect ERP',
      subject: 'Staff Salary Slip',
      creator: 'Almustafa Connect ERP',
    );

    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _schoolHeader(
                title: 'STAFF SALARY SLIP',
                subtitle: _monthLabel(salary.salaryMonth),
              ),
              pw.SizedBox(height: 20),
              _informationCard(
                children: [
                  _informationRow(
                    'Staff Name',
                    salary.staffName,
                    'Staff Code',
                    salary.staffCode,
                  ),
                  _informationRow(
                    'Designation',
                    salary.designation,
                    'Salary Month',
                    _monthLabel(salary.salaryMonth),
                  ),
                  _informationRow(
                    'Payment Status',
                    salary.isPaid ? 'Paid' : 'Unpaid',
                    'Payment Date',
                    salary.paymentDate == null
                        ? '-'
                        : _dateLabel(salary.paymentDate!),
                  ),
                  _informationRow(
                    'Payment Method',
                    salary.paymentMethod == null
                        ? '-'
                        : _paymentMethodLabel(
                            salary.paymentMethod!,
                          ),
                    'Reference',
                    salary.paymentReference.trim().isEmpty
                        ? '-'
                        : salary.paymentReference.trim(),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              _sectionTitle('Salary Calculation'),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.7,
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                },
                children: [
                  _amountRow(
                    label: 'Basic Salary',
                    value: salary.basicSalary,
                  ),
                  _amountRow(
                    label: 'Allowance',
                    value: salary.allowance,
                    positive: true,
                  ),
                  _amountRow(
                    label: 'Gross Salary',
                    value: salary.grossSalary,
                    bold: true,
                  ),
                  _amountRow(
                    label: 'Other Deduction',
                    value: salary.deduction,
                    negative: true,
                  ),
                  _amountRow(
                    label: 'Attendance / Unpaid Leave Deduction',
                    value: salary.attendanceDeduction,
                    negative: true,
                  ),
                  _amountRow(
                    label: 'Net Salary',
                    value: salary.netSalary,
                    bold: true,
                    highlight: true,
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              _sectionTitle('Attendance Summary'),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.7,
                ),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _tableCell('Present', bold: true),
                      _tableCell('Absent', bold: true),
                      _tableCell('Late', bold: true),
                      _tableCell('Leave', bold: true),
                      _tableCell('Total', bold: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell(
                        salary.presentDays.toString(),
                      ),
                      _tableCell(
                        salary.absentDays.toString(),
                      ),
                      _tableCell(
                        salary.lateDays.toString(),
                      ),
                      _tableCell(
                        salary.leaveDays.toString(),
                      ),
                      _tableCell(
                        salary.totalMarkedDays.toString(),
                      ),
                    ],
                  ),
                ],
              ),
              if (salary.remarks.trim().isNotEmpty) ...[
                pw.SizedBox(height: 18),
                _sectionTitle('Remarks'),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.grey400,
                    ),
                    borderRadius:
                        pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    salary.remarks.trim(),
                    style: const pw.TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  _signatureBox('Prepared By'),
                  _signatureBox('Received By'),
                  _signatureBox('Authorized By'),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Divider(
                color: PdfColors.grey400,
              ),
              pw.Text(
                'Computer-generated salary slip from Almustafa Connect ERP.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  color: PdfColors.grey700,
                  fontSize: 8,
                ),
              ),
            ],
          );
        },
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildMonthlyPayrollPdf({
    required List<StaffSalaryEntity> salaries,
    required DateTime salaryMonth,
    required PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document(
      title:
          'Monthly Payroll Report - ${_monthLabel(salaryMonth)}',
      author: 'Almustafa Connect ERP',
      subject: 'Monthly Staff Payroll Report',
      creator: 'Almustafa Connect ERP',
    );

    final paidSalaries = salaries
        .where((salary) => salary.isPaid)
        .toList();

    final unpaidSalaries = salaries
        .where((salary) => !salary.isPaid)
        .toList();

    final totalBasic = _sum(
      salaries,
      (salary) => salary.basicSalary,
    );
    final totalAllowance = _sum(
      salaries,
      (salary) => salary.allowance,
    );
    final totalDeduction = _sum(
      salaries,
      (salary) =>
          salary.deduction + salary.attendanceDeduction,
    );
    final totalNet = _sum(
      salaries,
      (salary) => salary.netSalary,
    );
    final paidAmount = _sum(
      paidSalaries,
      (salary) => salary.netSalary,
    );
    final outstandingAmount = _sum(
      unpaidSalaries,
      (salary) => salary.netSalary,
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat.copyWith(
          marginLeft: 22,
          marginRight: 22,
          marginTop: 24,
          marginBottom: 24,
        ),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _schoolHeader(
                title: 'MONTHLY STAFF PAYROLL REPORT',
                subtitle: _monthLabel(salaryMonth),
              ),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (context) {
          return pw.Column(
            children: [
              pw.Divider(
                color: PdfColors.grey400,
              ),
              pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Almustafa Connect ERP',
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 8,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (context) {
          return [
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _summaryBox(
                  'Staff',
                  salaries.length.toString(),
                ),
                _summaryBox(
                  'Total Payroll',
                  _currency(totalNet),
                ),
                _summaryBox(
                  'Paid',
                  _currency(paidAmount),
                ),
                _summaryBox(
                  'Outstanding',
                  _currency(outstandingAmount),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const [
                '#',
                'Staff',
                'Code',
                'Basic',
                'Allowance',
                'Deductions',
                'Net Salary',
                'Status',
              ],
              data: [
                for (var index = 0;
                    index < salaries.length;
                    index++)
                  [
                    '${index + 1}',
                    salaries[index].staffName,
                    salaries[index].staffCode,
                    _number(salaries[index].basicSalary),
                    _number(salaries[index].allowance),
                    _number(
                      salaries[index].deduction +
                          salaries[index]
                              .attendanceDeduction,
                    ),
                    _number(salaries[index].netSalary),
                    salaries[index].isPaid
                        ? 'Paid'
                        : 'Unpaid',
                  ],
              ],
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue900,
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 7,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              columnWidths: const {
                0: pw.FixedColumnWidth(22),
                1: pw.FlexColumnWidth(2.4),
                2: pw.FlexColumnWidth(1.1),
                3: pw.FlexColumnWidth(1.1),
                4: pw.FlexColumnWidth(1.1),
                5: pw.FlexColumnWidth(1.2),
                6: pw.FlexColumnWidth(1.2),
                7: pw.FlexColumnWidth(0.9),
              },
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 5,
              ),
              headerPadding:
                  const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.grey400,
                ),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text(
                    'Payroll Totals',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  _totalLine(
                    'Total Basic Salary',
                    totalBasic,
                  ),
                  _totalLine(
                    'Total Allowance',
                    totalAllowance,
                  ),
                  _totalLine(
                    'Total Deductions',
                    totalDeduction,
                  ),
                  _totalLine(
                    'Total Net Payroll',
                    totalNet,
                    bold: true,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 22),
            pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                _signatureBox('Prepared By'),
                _signatureBox('Checked By'),
                _signatureBox('Approved By'),
              ],
            ),
          ];
        },
      ),
    );

    return document.save();
  }

  static pw.Widget _schoolHeader({
    required String title,
    required String subtitle,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 48,
            height: 48,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(24),
            ),
            child: pw.Text(
              'AM',
              style: pw.TextStyle(
                color: PdfColors.blue900,
                fontWeight: pw.FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ALMUSTAFA MODEL SCHOOL',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Vip Colony, Suraj Miani, Multan',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _informationCard({
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey400,
        ),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: children,
      ),
    );
  }

  static pw.Widget _informationRow(
    String firstLabel,
    String firstValue,
    String secondLabel,
    String secondValue,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: _labelValue(
              firstLabel,
              firstValue,
            ),
          ),
          pw.SizedBox(width: 18),
          pw.Expanded(
            child: _labelValue(
              secondLabel,
              secondValue,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _labelValue(
    String label,
    String value,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 78,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: PdfColors.blue900,
        fontWeight: pw.FontWeight.bold,
        fontSize: 11,
      ),
    );
  }

  static pw.TableRow _amountRow({
    required String label,
    required double value,
    bool positive = false,
    bool negative = false,
    bool bold = false,
    bool highlight = false,
  }) {
    final textStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight:
          bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: negative
          ? PdfColors.red700
          : positive
              ? PdfColors.green700
              : PdfColors.black,
    );

    return pw.TableRow(
      decoration: highlight
          ? const pw.BoxDecoration(
              color: PdfColors.blue50,
            )
          : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: textStyle,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            _currency(value),
            textAlign: pw.TextAlign.right,
            style: textStyle,
          ),
        ),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(7),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight:
              bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _summaryBox(
    String label,
    String value,
  ) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(
          color: PdfColors.grey400,
        ),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              color: PdfColors.grey700,
              fontSize: 8,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalLine(
    String label,
    double value, {
    bool bold = false,
  }) {
    final style = pw.TextStyle(
      fontSize: 9,
      fontWeight:
          bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
        vertical: 2,
      ),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(
            _currency(value),
            style: style,
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureBox(String label) {
    return pw.SizedBox(
      width: 130,
      child: pw.Column(
        children: [
          pw.SizedBox(height: 32),
          pw.Divider(
            color: PdfColors.grey600,
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  static double _sum(
    List<StaffSalaryEntity> salaries,
    double Function(StaffSalaryEntity salary) selector,
  ) {
    return salaries.fold<double>(
      0,
      (total, salary) => total + selector(salary),
    );
  }

  static String _currency(double value) {
    return 'Rs. ${_number(value)}';
  }

  static String _number(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  static String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static String _monthLabel(DateTime date) {
    const months = [
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
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  static String _paymentMethodLabel(
    StaffSalaryPaymentMethod method,
  ) {
    switch (method) {
      case StaffSalaryPaymentMethod.cash:
        return 'Cash';
      case StaffSalaryPaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case StaffSalaryPaymentMethod.easypaisa:
        return 'Easypaisa';
      case StaffSalaryPaymentMethod.jazzCash:
        return 'JazzCash';
      case StaffSalaryPaymentMethod.cheque:
        return 'Cheque';
      case StaffSalaryPaymentMethod.other:
        return 'Other';
    }
  }
}