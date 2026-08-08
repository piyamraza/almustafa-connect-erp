import '../entities/cashbook_entry_entity.dart';
import '../entities/expense_category_entity.dart';
import '../entities/expense_entity.dart';
import '../entities/income_entry_entity.dart';
import '../entities/monthly_profit_loss_entity.dart';
import '../entities/payroll_auto_deductions_entity.dart';
import '../entities/payroll_profile_entity.dart';
import '../entities/payroll_record_entity.dart';
import '../entities/salary_history_entity.dart';

abstract class AccountsRepository {
  // ============================================================
  // Expense Categories
  // ============================================================

  Future<List<ExpenseCategoryEntity>> getExpenseCategories();

  Future<void> saveExpenseCategory(ExpenseCategoryEntity category);

  Future<void> setExpenseCategoryActive({
    required String categoryId,
    required bool isActive,
  });

  // ============================================================
  // Expenses
  // ============================================================

  Future<List<ExpenseEntity>> getExpenses();

  Future<void> saveExpense(ExpenseEntity expense);

  Future<void> updateExpenseStatus({
    required String expenseId,
    required ExpenseStatus status,
    required String actorId,
  });

  // ============================================================
  // Payroll Profiles
  // ============================================================

  Future<List<PayrollProfileEntity>> getPayrollProfiles();

  Future<void> savePayrollProfile(PayrollProfileEntity profile);

  Future<void> setPayrollProfileActive({
    required String profileId,
    required bool isActive,
  });

  Future<void> deletePayrollProfile(String profileId);

  // ============================================================
  // Payroll Records
  // ============================================================

  Future<List<PayrollRecordEntity>> getPayrollRecords();

  Future<void> savePayrollRecord(PayrollRecordEntity record);

  Future<void> updatePayrollStatus({
    required String payrollId,
    required PayrollPaymentStatus status,
    required String actorId,
    String paymentMethod,
    String referenceNumber,
  });

  Future<List<SalaryHistoryEntity>> getSalaryHistory();

  Future<void> applySalaryIncrements({
    required List<SalaryIncrementRequest> increments,
    required String actorId,
  });

  Future<void> initializeProfileBasedPayroll({required String actorId});

  // ============================================================
  // Employee Finance Payroll Integration
  // ============================================================

  Future<PayrollAutoDeductionsEntity> getPayrollAutoDeductions({
    required String employeeId,
    required PayrollEmployeeType employeeType,
    required DateTime payrollMonth,
  });

  Future<void> markEmployeeFinancePosted({
    required String payrollId,
    required String employeeId,
    required PayrollEmployeeType employeeType,
    required DateTime payrollMonth,
    required String actorId,
  });

  Future<void> reverseEmployeeFinancePosting({
    required String payrollId,
    required String actorId,
    required String reason,
  });

  // ============================================================
  // Income
  // ============================================================

  Future<List<IncomeEntryEntity>> getIncomeEntries();

  Future<void> saveIncomeEntry(IncomeEntryEntity entry);

  Future<void> reverseIncomeEntry({
    required String incomeEntryId,
    required String reason,
  });

  // ============================================================
  // Profit & Loss
  // ============================================================

  Future<List<MonthlyProfitLossEntity>> getMonthlyProfitLoss();

  Future<void> saveMonthlyProfitLoss(MonthlyProfitLossEntity snapshot);

  // ============================================================
  // Cashbook
  // ============================================================

  Future<List<CashbookEntryEntity>> getCashbookEntries();

  Future<void> saveCashbookEntry(CashbookEntryEntity entry);
}
