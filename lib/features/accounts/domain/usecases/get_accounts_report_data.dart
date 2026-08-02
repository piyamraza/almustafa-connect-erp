import '../entities/cashbook_entry_entity.dart';
import '../entities/expense_entity.dart';
import '../entities/income_entry_entity.dart';
import '../entities/monthly_profit_loss_entity.dart';
import '../entities/payroll_record_entity.dart';
import '../repositories/accounts_repository.dart';
import '../services/accounts_report_service.dart';

class GetAccountsReportData {
  const GetAccountsReportData(this._repository);

  final AccountsRepository _repository;

  Future<AccountsReportData> call({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final endExclusive = DateTime(toDate.year, toDate.month, toDate.day + 1);

    final results = await Future.wait<Object>([
      _repository.getIncomeEntries(),
      _repository.getExpenses(),
      _repository.getPayrollRecords(),
      _repository.getCashbookEntries(),
      _repository.getMonthlyProfitLoss(),
    ]);

    final income = (results[0] as List<IncomeEntryEntity>)
        .where(
          (item) =>
              !item.incomeDate.isBefore(fromDate) &&
              item.incomeDate.isBefore(endExclusive),
        )
        .toList();

    final expenses = (results[1] as List<ExpenseEntity>)
        .where(
          (item) =>
              !item.expenseDate.isBefore(fromDate) &&
              item.expenseDate.isBefore(endExclusive),
        )
        .toList();

    final payroll = (results[2] as List<PayrollRecordEntity>)
        .where(
          (item) =>
              !item.payrollMonth.isBefore(
                DateTime(fromDate.year, fromDate.month),
              ) &&
              item.payrollMonth.isBefore(
                DateTime(toDate.year, toDate.month + 1),
              ),
        )
        .toList();

    final cashbook = (results[3] as List<CashbookEntryEntity>)
        .where(
          (item) =>
              !item.entryDate.isBefore(fromDate) &&
              item.entryDate.isBefore(endExclusive),
        )
        .toList();

    final profitLoss = (results[4] as List<MonthlyProfitLossEntity>)
        .where(
          (item) =>
              !item.month.isBefore(DateTime(fromDate.year, fromDate.month)) &&
              item.month.isBefore(DateTime(toDate.year, toDate.month + 1)),
        )
        .toList();

    return AccountsReportData(
      fromDate: fromDate,
      toDate: toDate,
      incomeEntries: income,
      expenses: expenses,
      payrollRecords: payroll,
      cashbookEntries: cashbook,
      profitLossSnapshots: profitLoss,
    );
  }
}
