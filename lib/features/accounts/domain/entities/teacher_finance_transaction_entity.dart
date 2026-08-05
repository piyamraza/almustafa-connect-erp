import 'package:equatable/equatable.dart';

enum TeacherFinanceTransactionType {
  /// Advance or loan amount issued to the employee.
  disbursement,

  /// Advance or loan recovery posted when salary is paid.
  payrollRecovery,

  /// Recovery collected separately by the administration.
  manualRecovery,

  /// General correction to an existing employee finance account.
  adjustment,

  /// Employee finance account cancellation.
  cancellation,

  /// Additional salary payment.
  bonus,

  /// Additional recurring or one-time allowance.
  allowance,

  /// Salary penalty or fine.
  penalty,

  /// Deduction other than advance, loan or penalty.
  otherDeduction,

  /// Additional payment other than bonus or allowance.
  otherPayment,

  /// Manual positive or negative salary correction.
  salaryAdjustment,
}

enum TeacherFinanceTransactionDirection { debit, credit, neutral }

enum TeacherFinancePayrollEffect {
  increaseSalary,
  decreaseSalary,
  noPayrollEffect,
}

class TeacherFinanceTransactionEntity extends Equatable {
  const TeacherFinanceTransactionEntity({
    required this.id,
    required this.accountId,
    required this.employeeId,
    required this.employeeName,
    required this.transactionType,
    required this.amount,
    required this.transactionDate,
    required this.payrollId,
    required this.referenceNumber,
    required this.notes,
    required this.createdBy,
    required this.createdAt,
    this.payrollMonth,
    this.isPostedToPayroll = false,
    this.isReversed = false,
    this.reversedAt,
    this.reversedBy = '',
    this.reversalReason = '',
  });

  final String id;

  /// Parent Employee Finance account ID.
  ///
  /// It can remain empty for standalone Bonus, Allowance, Penalty,
  /// Other Payment, Other Deduction or Salary Adjustment entries.
  final String accountId;

  final String employeeId;
  final String employeeName;
  final TeacherFinanceTransactionType transactionType;

  /// Always store the amount as a positive value.
  ///
  /// Whether it increases or decreases salary is determined by
  /// [payrollEffect].
  final int amount;

  final DateTime transactionDate;

  /// Payroll record ID after the transaction is posted to payroll.
  final String payrollId;

  /// Optional month for which the transaction applies.
  final DateTime? payrollMonth;

  final String referenceNumber;
  final String notes;
  final String createdBy;
  final DateTime createdAt;

  /// True after this transaction has been included in a payroll record.
  final bool isPostedToPayroll;

  /// Reversed transactions must not affect payroll or balances again.
  final bool isReversed;
  final DateTime? reversedAt;
  final String reversedBy;
  final String reversalReason;

  bool get isValidAmount => amount > 0;

  bool get canBePostedToPayroll =>
      !isReversed &&
      !isPostedToPayroll &&
      payrollEffect != TeacherFinancePayrollEffect.noPayrollEffect;

  bool appliesToPayrollMonth(DateTime month) {
    if (payrollMonth == null) return true;

    return payrollMonth!.year == month.year &&
        payrollMonth!.month == month.month;
  }

  TeacherFinanceTransactionDirection get ledgerDirection {
    return switch (transactionType) {
      TeacherFinanceTransactionType.disbursement =>
        TeacherFinanceTransactionDirection.debit,

      TeacherFinanceTransactionType.payrollRecovery ||
      TeacherFinanceTransactionType.manualRecovery =>
        TeacherFinanceTransactionDirection.credit,

      TeacherFinanceTransactionType.bonus ||
      TeacherFinanceTransactionType.allowance ||
      TeacherFinanceTransactionType.otherPayment =>
        TeacherFinanceTransactionDirection.credit,

      TeacherFinanceTransactionType.penalty ||
      TeacherFinanceTransactionType.otherDeduction =>
        TeacherFinanceTransactionDirection.debit,

      TeacherFinanceTransactionType.adjustment ||
      TeacherFinanceTransactionType.salaryAdjustment ||
      TeacherFinanceTransactionType.cancellation =>
        TeacherFinanceTransactionDirection.neutral,
    };
  }

  TeacherFinancePayrollEffect get payrollEffect {
    return switch (transactionType) {
      TeacherFinanceTransactionType.bonus ||
      TeacherFinanceTransactionType.allowance ||
      TeacherFinanceTransactionType.otherPayment =>
        TeacherFinancePayrollEffect.increaseSalary,

      TeacherFinanceTransactionType.payrollRecovery ||
      TeacherFinanceTransactionType.penalty ||
      TeacherFinanceTransactionType.otherDeduction =>
        TeacherFinancePayrollEffect.decreaseSalary,

      TeacherFinanceTransactionType.salaryAdjustment =>
        TeacherFinancePayrollEffect.noPayrollEffect,

      TeacherFinanceTransactionType.disbursement ||
      TeacherFinanceTransactionType.manualRecovery ||
      TeacherFinanceTransactionType.adjustment ||
      TeacherFinanceTransactionType.cancellation =>
        TeacherFinancePayrollEffect.noPayrollEffect,
    };
  }

  bool get increasesSalary =>
      payrollEffect == TeacherFinancePayrollEffect.increaseSalary;

  bool get decreasesSalary =>
      payrollEffect == TeacherFinancePayrollEffect.decreaseSalary;

  bool get affectsOutstandingBalance {
    return switch (transactionType) {
      TeacherFinanceTransactionType.disbursement ||
      TeacherFinanceTransactionType.payrollRecovery ||
      TeacherFinanceTransactionType.manualRecovery ||
      TeacherFinanceTransactionType.adjustment ||
      TeacherFinanceTransactionType.cancellation => true,

      TeacherFinanceTransactionType.bonus ||
      TeacherFinanceTransactionType.allowance ||
      TeacherFinanceTransactionType.penalty ||
      TeacherFinanceTransactionType.otherDeduction ||
      TeacherFinanceTransactionType.otherPayment ||
      TeacherFinanceTransactionType.salaryAdjustment => false,
    };
  }

  TeacherFinanceTransactionEntity copyWith({
    String? id,
    String? accountId,
    String? employeeId,
    String? employeeName,
    TeacherFinanceTransactionType? transactionType,
    int? amount,
    DateTime? transactionDate,
    String? payrollId,
    DateTime? payrollMonth,
    bool clearPayrollMonth = false,
    String? referenceNumber,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    bool? isPostedToPayroll,
    bool? isReversed,
    DateTime? reversedAt,
    bool clearReversedAt = false,
    String? reversedBy,
    String? reversalReason,
  }) {
    return TeacherFinanceTransactionEntity(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      payrollId: payrollId ?? this.payrollId,
      payrollMonth: clearPayrollMonth
          ? null
          : payrollMonth ?? this.payrollMonth,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isPostedToPayroll: isPostedToPayroll ?? this.isPostedToPayroll,
      isReversed: isReversed ?? this.isReversed,
      reversedAt: clearReversedAt ? null : reversedAt ?? this.reversedAt,
      reversedBy: reversedBy ?? this.reversedBy,
      reversalReason: reversalReason ?? this.reversalReason,
    );
  }

  @override
  List<Object?> get props => [
    id,
    accountId,
    employeeId,
    employeeName,
    transactionType,
    amount,
    transactionDate,
    payrollId,
    payrollMonth,
    referenceNumber,
    notes,
    createdBy,
    createdAt,
    isPostedToPayroll,
    isReversed,
    reversedAt,
    reversedBy,
    reversalReason,
  ];
}
