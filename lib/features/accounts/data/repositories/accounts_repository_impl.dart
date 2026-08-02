import '../../domain/entities/cashbook_entry_entity.dart';
import '../../domain/entities/expense_category_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/income_entry_entity.dart';
import '../../domain/entities/monthly_profit_loss_entity.dart';
import '../../domain/entities/payroll_profile_entity.dart';
import '../../domain/entities/payroll_record_entity.dart';
import '../../domain/repositories/accounts_repository.dart';
import '../datasources/accounts_remote_datasource.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  AccountsRepositoryImpl(this._source);

  final AccountsRemoteDataSource _source;

  @override
  Future<List<ExpenseCategoryEntity>> getExpenseCategories() =>
      _source.getExpenseCategories();

  @override
  Future<void> saveExpenseCategory(ExpenseCategoryEntity category) =>
      _source.saveExpenseCategory(category);

  @override
  Future<void> setExpenseCategoryActive({
    required String categoryId,
    required bool isActive,
  }) => _source.setExpenseCategoryActive(
    categoryId: categoryId,
    isActive: isActive,
  );

  @override
  Future<List<ExpenseEntity>> getExpenses() => _source.getExpenses();

  @override
  Future<void> saveExpense(ExpenseEntity expense) =>
      _source.saveExpense(expense);

  @override
  Future<void> updateExpenseStatus({
    required String expenseId,
    required ExpenseStatus status,
    required String actorId,
  }) => _source.updateExpenseStatus(
    expenseId: expenseId,
    status: status,
    actorId: actorId,
  );

  @override
  Future<List<PayrollProfileEntity>> getPayrollProfiles() =>
      _source.getPayrollProfiles();

  @override
  Future<void> savePayrollProfile(PayrollProfileEntity profile) =>
      _source.savePayrollProfile(profile);

  @override
  Future<void> setPayrollProfileActive({
    required String profileId,
    required bool isActive,
  }) =>
      _source.setPayrollProfileActive(profileId: profileId, isActive: isActive);

  @override
  Future<List<PayrollRecordEntity>> getPayrollRecords() =>
      _source.getPayrollRecords();

  @override
  Future<void> savePayrollRecord(PayrollRecordEntity record) =>
      _source.savePayrollRecord(record);

  @override
  Future<void> updatePayrollStatus({
    required String payrollId,
    required PayrollPaymentStatus status,
    required String actorId,
    String paymentMethod = '',
    String referenceNumber = '',
  }) => _source.updatePayrollStatus(
    payrollId: payrollId,
    status: status,
    actorId: actorId,
    paymentMethod: paymentMethod,
    referenceNumber: referenceNumber,
  );

  @override
  Future<List<IncomeEntryEntity>> getIncomeEntries() =>
      _source.getIncomeEntries();

  @override
  Future<void> saveIncomeEntry(IncomeEntryEntity entry) =>
      _source.saveIncomeEntry(entry);

  @override
  Future<void> reverseIncomeEntry({
    required String incomeEntryId,
    required String reason,
  }) =>
      _source.reverseIncomeEntry(incomeEntryId: incomeEntryId, reason: reason);

  @override
  Future<List<MonthlyProfitLossEntity>> getMonthlyProfitLoss() =>
      _source.getMonthlyProfitLoss();

  @override
  Future<void> saveMonthlyProfitLoss(MonthlyProfitLossEntity snapshot) =>
      _source.saveMonthlyProfitLoss(snapshot);

  @override
  Future<List<CashbookEntryEntity>> getCashbookEntries() =>
      _source.getCashbookEntries();

  @override
  Future<void> saveCashbookEntry(CashbookEntryEntity entry) =>
      _source.saveCashbookEntry(entry);
}
