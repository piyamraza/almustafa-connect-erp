import '../entities/expense_entity.dart';
import '../entities/income_entry_entity.dart';
import '../entities/monthly_profit_loss_entity.dart';
import '../entities/payroll_record_entity.dart';
import '../repositories/accounts_repository.dart';

class GetProfitLossSnapshots {
  const GetProfitLossSnapshots(this._repository);

  final AccountsRepository _repository;

  Future<List<MonthlyProfitLossEntity>> call() {
    return _repository.getMonthlyProfitLoss();
  }
}

class GenerateMonthlyProfitLoss {
  const GenerateMonthlyProfitLoss(this._repository);

  final AccountsRepository _repository;

  Future<MonthlyProfitLossEntity> call({
    required DateTime month,
    required String actorId,
  }) async {
    if (actorId.trim().isEmpty) {
      throw ArgumentError(
        'Current authenticated user could not be identified.',
      );
    }

    final monthStart = DateTime(month.year, month.month);
    final monthEnd = DateTime(month.year, month.month + 1);

    final responses = await Future.wait<Object>([
      _repository.getIncomeEntries(),
      _repository.getExpenses(),
      _repository.getPayrollRecords(),
    ]);

    final incomeEntries = responses[0] as List<IncomeEntryEntity>;
    final expenses = responses[1] as List<ExpenseEntity>;
    final payrollRecords = responses[2] as List<PayrollRecordEntity>;

    final monthIncome = incomeEntries.where(
      (entry) =>
          entry.isActive &&
          !entry.incomeDate.isBefore(monthStart) &&
          entry.incomeDate.isBefore(monthEnd),
    );

    final feeIncome = monthIncome
        .where((entry) => entry.sourceType == IncomeSourceType.feePayment)
        .fold<int>(0, (sum, entry) => sum + entry.amount);

    final otherIncome = monthIncome
        .where((entry) => entry.sourceType != IncomeSourceType.feePayment)
        .fold<int>(0, (sum, entry) => sum + entry.amount);

    final monthExpenses = expenses.where(
      (expense) =>
          expense.status == ExpenseStatus.paid &&
          !expense.expenseDate.isBefore(monthStart) &&
          expense.expenseDate.isBefore(monthEnd),
    );

    final otherExpense = monthExpenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final salaryExpense = payrollRecords
        .where(
          (record) =>
              record.paymentStatus == PayrollPaymentStatus.paid &&
              record.payrollMonth.year == month.year &&
              record.payrollMonth.month == month.month,
        )
        .fold<int>(0, (sum, record) => sum + record.netSalary);

    final totalIncome = feeIncome + otherIncome;
    final totalExpenses = salaryExpense + otherExpense;
    final monthKey =
        '${month.year.toString().padLeft(4, '0')}-'
        '${month.month.toString().padLeft(2, '0')}';

    final result = MonthlyProfitLossEntity(
      id: monthKey,
      month: monthStart,
      totalFeeIncome: feeIncome,
      totalOtherIncome: otherIncome,
      totalIncome: totalIncome,
      totalSalaryExpense: salaryExpense,
      totalOtherExpense: otherExpense,
      totalExpenses: totalExpenses,
      netProfitLoss: totalIncome - totalExpenses,
      generatedAt: DateTime.now(),
      generatedBy: actorId,
    );

    await _repository.saveMonthlyProfitLoss(result);
    return result;
  }
}
