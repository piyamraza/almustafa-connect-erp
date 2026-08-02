import '../entities/cashbook_entry_entity.dart';
import '../entities/expense_entity.dart';
import '../entities/income_entry_entity.dart';
import '../entities/monthly_profit_loss_entity.dart';
import '../entities/payroll_record_entity.dart';
import '../repositories/accounts_repository.dart';

class AccountsOverviewData {
  const AccountsOverviewData({
    required this.expenses,
    required this.incomeEntries,
    required this.payrollRecords,
    required this.profitLoss,
    required this.cashbookEntries,
  });

  final List<ExpenseEntity> expenses;
  final List<IncomeEntryEntity> incomeEntries;
  final List<PayrollRecordEntity> payrollRecords;
  final List<MonthlyProfitLossEntity> profitLoss;
  final List<CashbookEntryEntity> cashbookEntries;
}

class GetAccountsOverview {
  const GetAccountsOverview(this._repository);

  final AccountsRepository _repository;

  Future<AccountsOverviewData> call() async {
    final results = await Future.wait<Object>([
      _repository.getExpenses(),
      _repository.getIncomeEntries(),
      _repository.getPayrollRecords(),
      _repository.getMonthlyProfitLoss(),
      _repository.getCashbookEntries(),
    ]);
    return AccountsOverviewData(
      expenses: results[0] as List<ExpenseEntity>,
      incomeEntries: results[1] as List<IncomeEntryEntity>,
      payrollRecords: results[2] as List<PayrollRecordEntity>,
      profitLoss: results[3] as List<MonthlyProfitLossEntity>,
      cashbookEntries: results[4] as List<CashbookEntryEntity>,
    );
  }
}
