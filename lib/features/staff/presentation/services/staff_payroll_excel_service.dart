import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/staff_salary_entity.dart';

class StaffPayrollExcelService {
  const StaffPayrollExcelService._();

  static const _excelMimeType =
      'application/vnd.openxmlformats-officedocument.'
      'spreadsheetml.sheet';

  static Future<void> exportMonthlyPayroll({
    required List<StaffSalaryEntity> salaries,
    required DateTime salaryMonth,
  }) async {
    final excel = Excel.createExcel();

    excel.rename(
      excel.getDefaultSheet() ?? 'Sheet1',
      'Payroll Summary',
    );

    final summarySheet = excel['Payroll Summary'];
    final detailsSheet = excel['Payroll Details'];

    _buildSummarySheet(
      sheet: summarySheet,
      salaries: salaries,
      salaryMonth: salaryMonth,
    );

    _buildDetailsSheet(
      sheet: detailsSheet,
      salaries: salaries,
      salaryMonth: salaryMonth,
    );

    excel.setDefaultSheet('Payroll Summary');

    final bytes = excel.save();

    if (bytes == null || bytes.isEmpty) {
      throw StateError(
        'Unable to generate payroll Excel file.',
      );
    }

    final fileName = _fileName(salaryMonth);

    await Share.shareXFiles(
      [
        XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: _excelMimeType,
        ),
      ],
      fileNameOverrides: [fileName],
      subject:
          'Staff Payroll - ${_monthLabel(salaryMonth)}',
      text:
          'Monthly staff payroll report for '
          '${_monthLabel(salaryMonth)}.',
    );
  }

  static void _buildSummarySheet({
    required Sheet sheet,
    required List<StaffSalaryEntity> salaries,
    required DateTime salaryMonth,
  }) {
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.white,
      backgroundColorHex:
          ExcelColor.fromHexString('#1E3A8A'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final subtitleStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex:
          ExcelColor.fromHexString('#2563EB'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final sectionStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex:
          ExcelColor.fromHexString('#475569'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final labelStyle = CellStyle(
      bold: true,
      backgroundColorHex:
          ExcelColor.fromHexString('#E2E8F0'),
      verticalAlign: VerticalAlign.Center,
    );

    final valueStyle = CellStyle(
      verticalAlign: VerticalAlign.Center,
    );

    final amountStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      numberFormat:
          CustomNumericNumFormat('#,##0.00'),
    );

    final boldAmountStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex:
          ExcelColor.fromHexString('#DBEAFE'),
      numberFormat:
          CustomNumericNumFormat('#,##0.00'),
    );

    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('D1'),
      customValue:
          TextCellValue('ALMUSTAFA MODEL SCHOOL'),
    );
    sheet.setMergedCellStyle(
      CellIndex.indexByString('A1'),
      titleStyle,
    );
    sheet.setRowHeight(0, 28);

    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('D2'),
      customValue: TextCellValue(
        'MONTHLY STAFF PAYROLL REPORT',
      ),
    );
    sheet.setMergedCellStyle(
      CellIndex.indexByString('A2'),
      subtitleStyle,
    );
    sheet.setRowHeight(1, 22);

    _writeCell(
      sheet,
      row: 3,
      column: 0,
      value: TextCellValue('Salary Month'),
      style: labelStyle,
    );
    _writeCell(
      sheet,
      row: 3,
      column: 1,
      value: TextCellValue(
        _monthLabel(salaryMonth),
      ),
      style: valueStyle,
    );
    _writeCell(
      sheet,
      row: 3,
      column: 2,
      value: TextCellValue('Generated On'),
      style: labelStyle,
    );
    _writeCell(
      sheet,
      row: 3,
      column: 3,
      value: TextCellValue(
        _dateTimeLabel(DateTime.now()),
      ),
      style: valueStyle,
    );

    sheet.merge(
      CellIndex.indexByString('A6'),
      CellIndex.indexByString('D6'),
      customValue: TextCellValue('PAYROLL SUMMARY'),
    );
    sheet.setMergedCellStyle(
      CellIndex.indexByString('A6'),
      sectionStyle,
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
    final totalOtherDeduction = _sum(
      salaries,
      (salary) => salary.deduction,
    );
    final totalAttendanceDeduction = _sum(
      salaries,
      (salary) => salary.attendanceDeduction,
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

    final summaryRows = <_SummaryRow>[
      _SummaryRow(
        label: 'Total Staff',
        value: IntCellValue(salaries.length),
      ),
      _SummaryRow(
        label: 'Paid Records',
        value: IntCellValue(paidSalaries.length),
      ),
      _SummaryRow(
        label: 'Unpaid Records',
        value: IntCellValue(unpaidSalaries.length),
      ),
      _SummaryRow(
        label: 'Total Basic Salary',
        value: DoubleCellValue(totalBasic),
        amount: true,
      ),
      _SummaryRow(
        label: 'Total Allowance',
        value: DoubleCellValue(totalAllowance),
        amount: true,
      ),
      _SummaryRow(
        label: 'Other Deductions',
        value: DoubleCellValue(totalOtherDeduction),
        amount: true,
      ),
      _SummaryRow(
        label: 'Attendance / Unpaid Leave Deduction',
        value:
            DoubleCellValue(totalAttendanceDeduction),
        amount: true,
      ),
      _SummaryRow(
        label: 'Total Net Payroll',
        value: DoubleCellValue(totalNet),
        amount: true,
        highlight: true,
      ),
      _SummaryRow(
        label: 'Paid Amount',
        value: DoubleCellValue(paidAmount),
        amount: true,
      ),
      _SummaryRow(
        label: 'Outstanding Amount',
        value: DoubleCellValue(outstandingAmount),
        amount: true,
        highlight: true,
      ),
    ];

    for (var index = 0;
        index < summaryRows.length;
        index++) {
      final row = 6 + index;
      final summary = summaryRows[index];

      sheet.merge(
        CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: row,
        ),
        CellIndex.indexByColumnRow(
          columnIndex: 2,
          rowIndex: row,
        ),
        customValue: TextCellValue(summary.label),
      );

      sheet.setMergedCellStyle(
        CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: row,
        ),
        labelStyle,
      );

      _writeCell(
        sheet,
        row: row,
        column: 3,
        value: summary.value,
        style: summary.highlight
            ? boldAmountStyle
            : summary.amount
                ? amountStyle
                : valueStyle,
      );
    }

    sheet.setColumnWidth(0, 26);
    sheet.setColumnWidth(1, 20);
    sheet.setColumnWidth(2, 26);
    sheet.setColumnWidth(3, 20);
  }

  static void _buildDetailsSheet({
    required Sheet sheet,
    required List<StaffSalaryEntity> salaries,
    required DateTime salaryMonth,
  }) {
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 15,
      fontColorHex: ExcelColor.white,
      backgroundColorHex:
          ExcelColor.fromHexString('#1E3A8A'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex:
          ExcelColor.fromHexString('#334155'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    final textStyle = CellStyle(
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    final centerStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final amountStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
      numberFormat:
          CustomNumericNumFormat('#,##0.00'),
    );

    final paidStyle = CellStyle(
      bold: true,
      fontColorHex:
          ExcelColor.fromHexString('#166534'),
      backgroundColorHex:
          ExcelColor.fromHexString('#DCFCE7'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final unpaidStyle = CellStyle(
      bold: true,
      fontColorHex:
          ExcelColor.fromHexString('#9A3412'),
      backgroundColorHex:
          ExcelColor.fromHexString('#FFEDD5'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('T1'),
      customValue: TextCellValue(
        'Staff Payroll Details - '
        '${_monthLabel(salaryMonth)}',
      ),
    );
    sheet.setMergedCellStyle(
      CellIndex.indexByString('A1'),
      titleStyle,
    );
    sheet.setRowHeight(0, 28);

    final headers = <String>[
      'Sr.',
      'Staff Name',
      'Staff Code',
      'Designation',
      'Salary Month',
      'Basic Salary',
      'Allowance',
      'Gross Salary',
      'Other Deduction',
      'Attendance / Unpaid Leave Deduction',
      'Net Salary',
      'Present',
      'Absent',
      'Late',
      'Leave',
      'Payment Status',
      'Payment Date',
      'Payment Method',
      'Payment Reference',
      'Remarks',
    ];

    for (var column = 0;
        column < headers.length;
        column++) {
      _writeCell(
        sheet,
        row: 2,
        column: column,
        value: TextCellValue(headers[column]),
        style: headerStyle,
      );
    }

    for (var index = 0;
        index < salaries.length;
        index++) {
      final salary = salaries[index];
      final row = index + 3;

      final values = <CellValue?>[
        IntCellValue(index + 1),
        TextCellValue(salary.staffName),
        TextCellValue(salary.staffCode),
        TextCellValue(salary.designation),
        TextCellValue(
          _monthLabel(salary.salaryMonth),
        ),
        DoubleCellValue(salary.basicSalary),
        DoubleCellValue(salary.allowance),
        DoubleCellValue(salary.grossSalary),
        DoubleCellValue(salary.deduction),
        DoubleCellValue(
          salary.attendanceDeduction,
        ),
        DoubleCellValue(salary.netSalary),
        IntCellValue(salary.presentDays),
        IntCellValue(salary.absentDays),
        IntCellValue(salary.lateDays),
        IntCellValue(salary.leaveDays),
        TextCellValue(
          salary.isPaid ? 'Paid' : 'Unpaid',
        ),
        TextCellValue(
          salary.paymentDate == null
              ? ''
              : _dateLabel(salary.paymentDate!),
        ),
        TextCellValue(
          salary.paymentMethod == null
              ? ''
              : _paymentMethodLabel(
                  salary.paymentMethod!,
                ),
        ),
        TextCellValue(
          salary.paymentReference,
        ),
        TextCellValue(salary.remarks),
      ];

      for (var column = 0;
          column < values.length;
          column++) {
        final isAmountColumn =
            column >= 5 && column <= 10;
        final isCenterColumn =
            column == 0 ||
            (column >= 11 && column <= 17);

        final style = column == 15
            ? salary.isPaid
                ? paidStyle
                : unpaidStyle
            : isAmountColumn
                ? amountStyle
                : isCenterColumn
                    ? centerStyle
                    : textStyle;

        _writeCell(
          sheet,
          row: row,
          column: column,
          value: values[column],
          style: style,
        );
      }
    }

    final widths = <double>[
      7,
      24,
      14,
      20,
      16,
      15,
      13,
      15,
      16,
      24,
      15,
      10,
      10,
      10,
      10,
      15,
      15,
      18,
      20,
      28,
    ];

    for (var column = 0;
        column < widths.length;
        column++) {
      sheet.setColumnWidth(
        column,
        widths[column],
      );
    }

    sheet.setRowHeight(2, 36);
  }

  static void _writeCell(
    Sheet sheet, {
    required int row,
    required int column,
    required CellValue? value,
    required CellStyle style,
  }) {
    sheet.updateCell(
      CellIndex.indexByColumnRow(
        columnIndex: column,
        rowIndex: row,
      ),
      value,
      cellStyle: style,
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

  static String _fileName(DateTime month) {
    final formattedMonth =
        month.month.toString().padLeft(2, '0');

    return 'Staff_Payroll_${month.year}_'
        '$formattedMonth.xlsx';
  }

  static String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static String _dateTimeLabel(DateTime date) {
    final hour =
        date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');

    return '${_dateLabel(date)} $hour:$minute';
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

class _SummaryRow {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.amount = false,
    this.highlight = false,
  });

  final String label;
  final CellValue value;
  final bool amount;
  final bool highlight;
}