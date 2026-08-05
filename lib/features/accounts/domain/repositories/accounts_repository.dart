import '../entities/cashbook_entry_entity.dart';
import '../entities/expense_category_entity.dart';
import '../entities/expense_entity.dart';
import '../entities/income_entry_entity.dart';
import '../entities/monthly_profit_loss_entity.dart';
import '../entities/payroll_profile_entity.dart';
import '../entities/payroll_record_entity.dart';

abstract class AccountsRepository {
  Future<List<ExpenseCategoryEntity>> getExpenseCategories();
  Future<void> saveExpenseCategory(ExpenseCategoryEntity category);
  Future<void> setExpenseCategoryActive({
    required String categoryId,
    required bool isActive,
  });

  Future<List<ExpenseEntity>> getExpenses();
  Future<void> saveExpense(ExpenseEntity expense);
  Future<void> updateExpenseStatus({
    required String expenseId,
    required ExpenseStatus status,
    required String actorId,
  });

  Future<List<PayrollProfileEntity>> getPayrollProfiles();
  Future<void> savePayrollProfile(PayrollProfileEntity profile);
  Future<void> setPayrollProfileActive({
    required String profileId,
    required bool isActive,
  });
  Future<List<PayrollRecordEntity>> getPayrollRecords();
  Future<void> savePayrollRecord(PayrollRecordEntity record);
  Future<void> updatePayrollStatus({
    required String payrollId,
    required PayrollPaymentStatus status,
    required String actorId,
    String paymentMethod,
    String referenceNumber,
  });
  // ===============================
  // Teacher Advance / Loan Payroll
  // ===============================

  Future<int> getAdvanceDeductionForPayroll({required String employeeId});

  Future<int> getLoanDeductionForPayroll({required String employeeId});

  Future<int> getOtherPayrollDeductions({required String employeeId});

  Future<List<IncomeEntryEntity>> getIncomeEntries();
  Future<void> saveIncomeEntry(IncomeEntryEntity entry);
  Future<void> reverseIncomeEntry({
    required String incomeEntryId,
    required String reason,
  });

  Future<List<MonthlyProfitLossEntity>> getMonthlyProfitLoss();
  Future<void> saveMonthlyProfitLoss(MonthlyProfitLossEntity snapshot);
  Future<List<CashbookEntryEntity>> getCashbookEntries();
  Future<void> saveCashbookEntry(CashbookEntryEntity entry);
}
