import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/cashbook_entry_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/payroll_record_entity.dart';
import '../../domain/services/accounts_report_service.dart';

class AccountsReportServiceImpl implements AccountsReportService {
  const AccountsReportServiceImpl();

  @override
  Future<void> exportPdf({
    required AccountsReportType reportType,
    required AccountsReportData data,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Almustafa Model School',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              '${_title(reportType)} Report',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('${_date(data.fromDate)} to ${_date(data.toDate)}'),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (context) => [
          _pdfSummary(reportType, data),
          pw.SizedBox(height: 12),
          _pdfTable(reportType, data),
        ],
      ),
    );

    final bytes = await document.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_fileName(reportType, data)}.pdf',
    );
  }

  @override
  Future<void> exportExcel({
    required AccountsReportType reportType,
    required AccountsReportData data,
  }) async {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    final sheetName = _title(reportType);
    final sheet = excel[sheetName];

    _writeExcel(sheet, reportType, data);

    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.delete(defaultSheet);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('Unable to generate Excel report.');
    }

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/${_fileName(reportType, data)}.xlsx';
    final file = File(path);
    await file.writeAsBytes(encoded, flush: true);

    await Share.shareXFiles([
      XFile(path),
    ], subject: '${_title(reportType)} Report');
  }

  pw.Widget _pdfSummary(AccountsReportType type, AccountsReportData data) {
    final totals = _totals(type, data);

    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: totals.entries
          .map(
            (entry) => pw.Container(
              width: 160,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(entry.key),
                  pw.Text(
                    'Rs. ${entry.value}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _pdfTable(AccountsReportType type, AccountsReportData data) {
    final table = _table(type, data);

    if (table.rows.isEmpty) {
      return pw.Text('No records available for this period.');
    }

    return pw.TableHelper.fromTextArray(
      headers: table.headers,
      data: table.rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  void _writeExcel(
    Sheet sheet,
    AccountsReportType type,
    AccountsReportData data,
  ) {
    sheet.appendRow([TextCellValue('Almustafa Model School')]);
    sheet.appendRow([TextCellValue('${_title(type)} Report')]);
    sheet.appendRow([
      TextCellValue('${_date(data.fromDate)} to ${_date(data.toDate)}'),
    ]);
    sheet.appendRow([]);

    final totals = _totals(type, data);
    for (final entry in totals.entries) {
      sheet.appendRow([TextCellValue(entry.key), IntCellValue(entry.value)]);
    }

    sheet.appendRow([]);

    final table = _table(type, data);
    sheet.appendRow(table.headers.map(TextCellValue.new).toList());

    for (final row in table.rows) {
      sheet.appendRow(row.map((value) => TextCellValue(value)).toList());
    }
  }

  Map<String, int> _totals(AccountsReportType type, AccountsReportData data) {
    switch (type) {
      case AccountsReportType.income:
        final active = data.incomeEntries
            .where((entry) => entry.isActive)
            .fold<int>(0, (sum, entry) => sum + entry.amount);
        return {'Active Income': active, 'Entries': data.incomeEntries.length};

      case AccountsReportType.expenses:
        final paid = data.expenses
            .where((entry) => entry.status == ExpenseStatus.paid)
            .fold<int>(0, (sum, entry) => sum + entry.amount);
        return {'Paid Expenses': paid, 'Entries': data.expenses.length};

      case AccountsReportType.payroll:
        final paid = data.payrollRecords
            .where((entry) => entry.paymentStatus == PayrollPaymentStatus.paid)
            .fold<int>(0, (sum, entry) => sum + entry.netSalary);
        return {'Paid Payroll': paid, 'Records': data.payrollRecords.length};

      case AccountsReportType.cashbook:
        final income = data.cashbookEntries
            .where((entry) => entry.entryType == CashbookEntryType.income)
            .fold<int>(0, (sum, entry) => sum + entry.amount);
        final expense = data.cashbookEntries
            .where((entry) => entry.entryType == CashbookEntryType.expense)
            .fold<int>(0, (sum, entry) => sum + entry.amount);
        return {
          'Income': income,
          'Expense': expense,
          'Balance': income - expense,
        };

      case AccountsReportType.profitLoss:
        final income = data.profitLossSnapshots.fold<int>(
          0,
          (sum, entry) => sum + entry.totalIncome,
        );
        final expense = data.profitLossSnapshots.fold<int>(
          0,
          (sum, entry) => sum + entry.totalExpenses,
        );
        return {
          'Total Income': income,
          'Total Expense': expense,
          'Net Profit / Loss': income - expense,
        };
    }
  }

  _ReportTable _table(AccountsReportType type, AccountsReportData data) {
    switch (type) {
      case AccountsReportType.income:
        return _ReportTable(
          headers: const [
            'Date',
            'Type',
            'Description',
            'Student',
            'Method',
            'Status',
            'Amount',
          ],
          rows: data.incomeEntries
              .map(
                (entry) => [
                  _date(entry.incomeDate),
                  entry.incomeType.name,
                  entry.description,
                  entry.studentName,
                  entry.paymentMethod,
                  entry.status.name,
                  entry.amount.toString(),
                ],
              )
              .toList(),
        );

      case AccountsReportType.expenses:
        return _ReportTable(
          headers: const [
            'Date',
            'Category',
            'Description',
            'Payee',
            'Method',
            'Status',
            'Amount',
          ],
          rows: data.expenses
              .map(
                (entry) => [
                  _date(entry.expenseDate),
                  entry.categoryName,
                  entry.description,
                  entry.payeeName,
                  entry.paymentMethod,
                  entry.status.name,
                  entry.amount.toString(),
                ],
              )
              .toList(),
        );

      case AccountsReportType.payroll:
        return _ReportTable(
          headers: const [
            'Month',
            'Employee',
            'Basic',
            'Allowances',
            'Deductions',
            'Bonus',
            'Net',
            'Status',
          ],
          rows: data.payrollRecords
              .map(
                (entry) => [
                  _month(entry.payrollMonth),
                  entry.employeeName,
                  entry.basicSalary.toString(),
                  entry.allowances.toString(),
                  (entry.deductions +
                          entry.absenceDeduction +
                          entry.advanceDeduction +
                          entry.loanDeduction)
                      .toString(),
                  entry.bonus.toString(),
                  entry.netSalary.toString(),
                  entry.paymentStatus.name,
                ],
              )
              .toList(),
        );

      case AccountsReportType.cashbook:
        var balance = 0;
        final rows = <List<String>>[];

        for (final entry in data.cashbookEntries) {
          balance += entry.entryType == CashbookEntryType.income
              ? entry.amount
              : -entry.amount;

          rows.add([
            _date(entry.entryDate),
            entry.entryType.name,
            entry.description,
            entry.paymentMethod,
            entry.referenceNumber,
            entry.amount.toString(),
            balance.toString(),
          ]);
        }

        return _ReportTable(
          headers: const [
            'Date',
            'Type',
            'Description',
            'Method',
            'Reference',
            'Amount',
            'Balance',
          ],
          rows: rows,
        );

      case AccountsReportType.profitLoss:
        return _ReportTable(
          headers: const [
            'Month',
            'Fee Income',
            'Other Income',
            'Total Income',
            'Salary Expense',
            'Other Expense',
            'Total Expense',
            'Profit / Loss',
          ],
          rows: data.profitLossSnapshots
              .map(
                (entry) => [
                  _month(entry.month),
                  entry.totalFeeIncome.toString(),
                  entry.totalOtherIncome.toString(),
                  entry.totalIncome.toString(),
                  entry.totalSalaryExpense.toString(),
                  entry.totalOtherExpense.toString(),
                  entry.totalExpenses.toString(),
                  entry.netProfitLoss.toString(),
                ],
              )
              .toList(),
        );
    }
  }

  String _fileName(AccountsReportType type, AccountsReportData data) {
    return 'accounts_${type.name}_'
        '${_compactDate(data.fromDate)}_'
        '${_compactDate(data.toDate)}';
  }

  String _title(AccountsReportType type) {
    switch (type) {
      case AccountsReportType.profitLoss:
        return 'Profit and Loss';
      case AccountsReportType.income:
        return 'Income';
      case AccountsReportType.expenses:
        return 'Expense';
      case AccountsReportType.payroll:
        return 'Payroll';
      case AccountsReportType.cashbook:
        return 'Cashbook';
    }
  }

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  String _compactDate(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _month(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }
}

class _ReportTable {
  const _ReportTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;
}
