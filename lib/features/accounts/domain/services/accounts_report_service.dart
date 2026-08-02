import '../entities/cashbook_entry_entity.dart';
import '../entities/expense_entity.dart';
import '../entities/income_entry_entity.dart';
import '../entities/monthly_profit_loss_entity.dart';
import '../entities/payroll_record_entity.dart';

enum AccountsReportType { profitLoss, income, expenses, payroll, cashbook }

class AccountsReportData {
  const AccountsReportData({
    required this.fromDate,
    required this.toDate,
    required this.incomeEntries,
    required this.expenses,
    required this.payrollRecords,
    required this.cashbookEntries,
    required this.profitLossSnapshots,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final List<IncomeEntryEntity> incomeEntries;
  final List<ExpenseEntity> expenses;
  final List<PayrollRecordEntity> payrollRecords;
  final List<CashbookEntryEntity> cashbookEntries;
  final List<MonthlyProfitLossEntity> profitLossSnapshots;
}

abstract class AccountsReportService {
  Future<void> exportPdf({
    required AccountsReportType reportType,
    required AccountsReportData data,
  });

  Future<void> exportExcel({
    required AccountsReportType reportType,
    required AccountsReportData data,
  });
}
