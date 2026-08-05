import 'package:equatable/equatable.dart';

enum TeacherFinanceType {
  advance,
  loan,
  salaryAdjustment,
  bonus,
  penalty,
  allowance,
  otherDeduction,
  otherPayment,
}

enum TeacherFinanceRecoveryMode { none, oneTime, monthly }

enum TeacherFinanceStatus { active, closed, cancelled }

class TeacherFinanceAccountEntity extends Equatable {
  const TeacherFinanceAccountEntity({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.financeType,
    required this.principalAmount,
    required this.monthlyRecoveryAmount,
    required this.recoveredAmount,
    required this.outstandingAmount,
    required this.issueDate,
    required this.recoveryStartMonth,
    required this.status,
    required this.approvedBy,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.recoveryMode = TeacherFinanceRecoveryMode.none,
    this.closedAt,
  });

  final String id;
  final String employeeId;
  final String employeeName;

  /// Advance, loan, bonus, allowance, penalty,
  /// salary adjustment, other deduction or other payment.
  final TeacherFinanceType financeType;

  /// Original approved transaction amount.
  ///
  /// This field is retained as [principalAmount] to remain compatible with
  /// existing Advance and Loan records. For non-recoverable entries, it
  /// represents the approved transaction amount.
  final int principalAmount;

  /// Amount to recover from each monthly payroll.
  ///
  /// It remains zero for entries that do not use monthly recovery.
  final int monthlyRecoveryAmount;

  /// Amount already recovered through payroll or manual entries.
  final int recoveredAmount;

  /// Remaining recoverable balance.
  ///
  /// For Bonus, Allowance and Other Payment entries, this normally remains
  /// zero because those entries are additions rather than recoveries.
  final int outstandingAmount;

  final DateTime issueDate;

  /// Month from which this item becomes applicable to payroll.
  final DateTime recoveryStartMonth;

  final TeacherFinanceRecoveryMode recoveryMode;
  final TeacherFinanceStatus status;
  final String approvedBy;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  bool get isActive => status == TeacherFinanceStatus.active;

  bool get isRecoverable =>
      recoveryMode != TeacherFinanceRecoveryMode.none && outstandingAmount > 0;

  bool get isMonthlyRecovery =>
      recoveryMode == TeacherFinanceRecoveryMode.monthly &&
      outstandingAmount > 0;

  bool get isOneTimeRecovery =>
      recoveryMode == TeacherFinanceRecoveryMode.oneTime &&
      outstandingAmount > 0;

  bool get increasesSalary {
    return switch (financeType) {
      TeacherFinanceType.bonus ||
      TeacherFinanceType.allowance ||
      TeacherFinanceType.otherPayment => true,
      _ => false,
    };
  }

  bool get decreasesSalary {
    return switch (financeType) {
      TeacherFinanceType.advance ||
      TeacherFinanceType.loan ||
      TeacherFinanceType.penalty ||
      TeacherFinanceType.otherDeduction => true,
      _ => false,
    };
  }

  bool get isSalaryAdjustment =>
      financeType == TeacherFinanceType.salaryAdjustment;

  bool appliesToPayrollMonth(DateTime payrollMonth) {
    final targetMonth = DateTime(payrollMonth.year, payrollMonth.month);
    final startMonth = DateTime(
      recoveryStartMonth.year,
      recoveryStartMonth.month,
    );

    return !targetMonth.isBefore(startMonth);
  }

  int deductionForPayrollMonth(DateTime payrollMonth) {
    if (!isActive || !decreasesSalary || !appliesToPayrollMonth(payrollMonth)) {
      return 0;
    }

    if (recoveryMode == TeacherFinanceRecoveryMode.none) {
      return principalAmount;
    }

    if (recoveryMode == TeacherFinanceRecoveryMode.oneTime) {
      return outstandingAmount;
    }

    if (recoveryMode == TeacherFinanceRecoveryMode.monthly) {
      if (monthlyRecoveryAmount <= 0) return 0;

      return monthlyRecoveryAmount > outstandingAmount
          ? outstandingAmount
          : monthlyRecoveryAmount;
    }

    return 0;
  }

  int additionForPayrollMonth(DateTime payrollMonth) {
    if (!isActive || !increasesSalary || !appliesToPayrollMonth(payrollMonth)) {
      return 0;
    }

    return principalAmount;
  }

  TeacherFinanceAccountEntity copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    TeacherFinanceType? financeType,
    int? principalAmount,
    int? monthlyRecoveryAmount,
    int? recoveredAmount,
    int? outstandingAmount,
    DateTime? issueDate,
    DateTime? recoveryStartMonth,
    TeacherFinanceRecoveryMode? recoveryMode,
    TeacherFinanceStatus? status,
    String? approvedBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
    bool clearClosedAt = false,
  }) {
    return TeacherFinanceAccountEntity(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      financeType: financeType ?? this.financeType,
      principalAmount: principalAmount ?? this.principalAmount,
      monthlyRecoveryAmount:
          monthlyRecoveryAmount ?? this.monthlyRecoveryAmount,
      recoveredAmount: recoveredAmount ?? this.recoveredAmount,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      issueDate: issueDate ?? this.issueDate,
      recoveryStartMonth: recoveryStartMonth ?? this.recoveryStartMonth,
      recoveryMode: recoveryMode ?? this.recoveryMode,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: clearClosedAt ? null : closedAt ?? this.closedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    financeType,
    principalAmount,
    monthlyRecoveryAmount,
    recoveredAmount,
    outstandingAmount,
    issueDate,
    recoveryStartMonth,
    recoveryMode,
    status,
    approvedBy,
    notes,
    createdAt,
    updatedAt,
    closedAt,
  ];
}
