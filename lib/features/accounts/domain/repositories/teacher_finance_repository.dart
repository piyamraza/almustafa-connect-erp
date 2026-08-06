import '../entities/teacher_finance_account_entity.dart';
import '../entities/teacher_finance_transaction_entity.dart';

abstract class TeacherFinanceRepository {
  String generateAccountId();

  String generateTransactionId();

  // =========================================================
  // Employee Finance Accounts
  // =========================================================

  Future<List<TeacherFinanceAccountEntity>> getAccounts({
    String? employeeId,
    TeacherFinanceEmployeeType? employeeType,
    TeacherFinanceType? financeType,
    TeacherFinanceRecoveryMode? recoveryMode,
    TeacherFinanceStatus? status,
  });

  Future<TeacherFinanceAccountEntity?> getAccountById({
    required String accountId,
  });

  Future<void> createAccount(
    TeacherFinanceAccountEntity account,
  );

  Future<void> updateAccount(
    TeacherFinanceAccountEntity account,
  );

  Future<void> cancelAccount({
    required String accountId,
    required String actorId,
    required String reason,
  });

  // =========================================================
  // Employee Finance Transactions
  // =========================================================

  Future<List<TeacherFinanceTransactionEntity>> getTransactions({
    String? accountId,
    String? employeeId,
    TeacherFinanceEmployeeType? employeeType,
    TeacherFinanceTransactionType? transactionType,
    DateTime? payrollMonth,
    bool? isPostedToPayroll,
    bool includeReversed = false,
  });

  Future<TeacherFinanceTransactionEntity?> getTransactionById({
    required String transactionId,
  });

  Future<void> saveTransaction(
    TeacherFinanceTransactionEntity transaction,
  );

  /// Creates a standalone payroll transaction such as:
  ///
  /// Bonus, Allowance, Penalty, Other Deduction,
  /// Other Payment or Salary Adjustment.
  ///
  /// Standalone transactions do not require an Advance/Loan account.
  Future<void> createStandaloneTransaction(
    TeacherFinanceTransactionEntity transaction,
  );

  Future<void> reverseTransaction({
    required String transactionId,
    required String actorId,
    required String reason,
  });

  // =========================================================
  // Advance / Loan Recovery
  // =========================================================

  Future<void> applyRecovery({
    required String accountId,
    required int amount,
    required TeacherFinanceTransactionType transactionType,
    required String actorId,
    String payrollId = '',
    String referenceNumber = '',
    String notes = '',
  });

  /// Returns active Advance and Loan accounts that are applicable
  /// to the selected payroll month.
  Future<List<TeacherFinanceAccountEntity>> getRecoverableAccounts({
    required String employeeId,
    required TeacherFinanceEmployeeType employeeType,
    required DateTime payrollMonth,
  });

  // =========================================================
  // Payroll Integration
  // =========================================================

  /// Returns all unposted Employee Finance transactions that should
  /// increase or decrease salary for the selected payroll month.
  Future<List<TeacherFinanceTransactionEntity>>
      getPendingPayrollTransactions({
    required String employeeId,
    required TeacherFinanceEmployeeType employeeType,
    required DateTime payrollMonth,
  });

  /// Marks Employee Finance transactions as posted after payroll
  /// has been successfully generated.
  Future<void> markTransactionsPostedToPayroll({
    required List<String> transactionIds,
    required String payrollId,
    required DateTime payrollMonth,
    required String actorId,
  });

  /// Posts Advance and Loan recoveries after salary is marked paid.
  ///
  /// Balance reduction must happen only after actual salary payment,
  /// not merely when payroll is generated.
  Future<void> postPayrollRecoveries({
    required String payrollId,
    required String employeeId,
    required TeacherFinanceEmployeeType employeeType,
    required int advanceAmount,
    required int loanAmount,
    required String actorId,
    String referenceNumber = '',
  });

  /// Reverses finance postings if a paid payroll is later reversed.
  Future<void> reversePayrollPosting({
    required String payrollId,
    required String actorId,
    required String reason,
  });
}