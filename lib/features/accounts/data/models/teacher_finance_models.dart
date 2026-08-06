import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/teacher_finance_account_entity.dart';
import '../../domain/entities/teacher_finance_transaction_entity.dart';

class TeacherFinanceAccountModel extends TeacherFinanceAccountEntity {
  const TeacherFinanceAccountModel({
    required super.id,
    required super.employeeId,
    required super.employeeName,
    required super.financeType,
    required super.principalAmount,
    required super.monthlyRecoveryAmount,
    required super.recoveredAmount,
    required super.outstandingAmount,
    required super.issueDate,
    required super.recoveryStartMonth,
    required super.status,
    required super.approvedBy,
    required super.notes,
    required super.createdAt,
    required super.updatedAt,
    super.employeeType,
    super.recoveryMode,
    super.closedAt,
  });

  factory TeacherFinanceAccountModel.fromEntity(
    TeacherFinanceAccountEntity entity,
  ) {
    return TeacherFinanceAccountModel(
      id: entity.id,
      employeeId: entity.employeeId,
      employeeName: entity.employeeName,
      employeeType: entity.employeeType,
      financeType: entity.financeType,
      principalAmount: entity.principalAmount,
      monthlyRecoveryAmount: entity.monthlyRecoveryAmount,
      recoveredAmount: entity.recoveredAmount,
      outstandingAmount: entity.outstandingAmount,
      issueDate: entity.issueDate,
      recoveryStartMonth: entity.recoveryStartMonth,
      recoveryMode: entity.recoveryMode,
      status: entity.status,
      approvedBy: entity.approvedBy,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      closedAt: entity.closedAt,
    );
  }

  factory TeacherFinanceAccountModel.fromMap(Map<String, dynamic> map) {
    final financeType = TeacherFinanceType.values.firstWhere(
      (value) => value.name == map['financeType'],
      orElse: () => TeacherFinanceType.advance,
    );

    return TeacherFinanceAccountModel(
      id: map['id'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      employeeType: _employeeType(map['employeeType']),
      financeType: financeType,
      principalAmount: _int(map['principalAmount']),
      monthlyRecoveryAmount: _int(map['monthlyRecoveryAmount']),
      recoveredAmount: _int(map['recoveredAmount']),
      outstandingAmount: _int(map['outstandingAmount']),
      issueDate: _date(map['issueDate']) ?? DateTime.now(),
      recoveryStartMonth:
          _date(map['recoveryStartMonth']) ?? DateTime.now(),
      recoveryMode: _recoveryMode(
        map['recoveryMode'],
        financeType: financeType,
        monthlyRecoveryAmount: _int(map['monthlyRecoveryAmount']),
      ),
      status: TeacherFinanceStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => TeacherFinanceStatus.active,
      ),
      approvedBy: map['approvedBy'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      updatedAt: _date(map['updatedAt']) ?? DateTime.now(),
      closedAt: _date(map['closedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeType': employeeType.name,
      'financeType': financeType.name,
      'principalAmount': principalAmount,
      'monthlyRecoveryAmount': monthlyRecoveryAmount,
      'recoveredAmount': recoveredAmount,
      'outstandingAmount': outstandingAmount,
      'issueDate': issueDate.toIso8601String(),
      'recoveryStartMonth': recoveryStartMonth.toIso8601String(),
      'recoveryMode': recoveryMode.name,
      'status': status.name,
      'approvedBy': approvedBy,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
    };
  }
}

class TeacherFinanceTransactionModel
    extends TeacherFinanceTransactionEntity {
  const TeacherFinanceTransactionModel({
    required super.id,
    required super.accountId,
    required super.employeeId,
    required super.employeeName,
    required super.transactionType,
    required super.amount,
    required super.transactionDate,
    required super.payrollId,
    required super.referenceNumber,
    required super.notes,
    required super.createdBy,
    required super.createdAt,
    super.payrollMonth,
    super.payrollEffectOverride,
    super.isPostedToPayroll,
    super.isReversed,
    super.reversedAt,
    super.reversedBy,
    super.reversalReason,
  });

  factory TeacherFinanceTransactionModel.fromEntity(
    TeacherFinanceTransactionEntity entity,
  ) {
    return TeacherFinanceTransactionModel(
      id: entity.id,
      accountId: entity.accountId,
      employeeId: entity.employeeId,
      employeeName: entity.employeeName,
      transactionType: entity.transactionType,
      amount: entity.amount,
      transactionDate: entity.transactionDate,
      payrollId: entity.payrollId,
      payrollMonth: entity.payrollMonth,
      payrollEffectOverride: entity.payrollEffectOverride,
      referenceNumber: entity.referenceNumber,
      notes: entity.notes,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      isPostedToPayroll: entity.isPostedToPayroll,
      isReversed: entity.isReversed,
      reversedAt: entity.reversedAt,
      reversedBy: entity.reversedBy,
      reversalReason: entity.reversalReason,
    );
  }

  factory TeacherFinanceTransactionModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return TeacherFinanceTransactionModel(
      id: map['id'] as String? ?? '',
      accountId: map['accountId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      transactionType:
          TeacherFinanceTransactionType.values.firstWhere(
        (value) => value.name == map['transactionType'],
        orElse: () => TeacherFinanceTransactionType.adjustment,
      ),
      amount: _int(map['amount']),
      transactionDate:
          _date(map['transactionDate']) ?? DateTime.now(),
      payrollId: map['payrollId'] as String? ?? '',
      payrollMonth: _date(map['payrollMonth']),
      payrollEffectOverride:
          _payrollEffect(map['payrollEffectOverride']),
      referenceNumber: map['referenceNumber'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      isPostedToPayroll: _bool(map['isPostedToPayroll']),
      isReversed: _bool(map['isReversed']),
      reversedAt: _date(map['reversedAt']),
      reversedBy: map['reversedBy'] as String? ?? '',
      reversalReason: map['reversalReason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'transactionType': transactionType.name,
      'amount': amount,
      'transactionDate': transactionDate.toIso8601String(),
      'payrollId': payrollId,
      'payrollMonth': payrollMonth?.toIso8601String(),
      'payrollEffectOverride': payrollEffectOverride?.name,
      'referenceNumber': referenceNumber,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'isPostedToPayroll': isPostedToPayroll,
      'isReversed': isReversed,
      'reversedAt': reversedAt?.toIso8601String(),
      'reversedBy': reversedBy,
      'reversalReason': reversalReason,
    };
  }
}

TeacherFinanceEmployeeType _employeeType(dynamic value) {
  if (value is String) {
    return TeacherFinanceEmployeeType.values.firstWhere(
      (item) => item.name == value.trim().toLowerCase(),
      orElse: () => TeacherFinanceEmployeeType.teacher,
    );
  }

  return TeacherFinanceEmployeeType.teacher;
}

TeacherFinancePayrollEffect? _payrollEffect(dynamic value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }

  for (final effect in TeacherFinancePayrollEffect.values) {
    if (effect.name == value.trim()) {
      return effect;
    }
  }

  return null;
}

TeacherFinanceRecoveryMode _recoveryMode(
  dynamic value, {
  required TeacherFinanceType financeType,
  required int monthlyRecoveryAmount,
}) {
  if (value is String) {
    return TeacherFinanceRecoveryMode.values.firstWhere(
      (item) => item.name == value,
      orElse: () => _legacyRecoveryMode(
        financeType: financeType,
        monthlyRecoveryAmount: monthlyRecoveryAmount,
      ),
    );
  }

  return _legacyRecoveryMode(
    financeType: financeType,
    monthlyRecoveryAmount: monthlyRecoveryAmount,
  );
}

TeacherFinanceRecoveryMode _legacyRecoveryMode({
  required TeacherFinanceType financeType,
  required int monthlyRecoveryAmount,
}) {
  if ((financeType == TeacherFinanceType.advance ||
          financeType == TeacherFinanceType.loan) &&
      monthlyRecoveryAmount > 0) {
    return TeacherFinanceRecoveryMode.monthly;
  }

  if (financeType == TeacherFinanceType.penalty ||
      financeType == TeacherFinanceType.otherDeduction) {
    return TeacherFinanceRecoveryMode.oneTime;
  }

  return TeacherFinanceRecoveryMode.none;
}

int _int(dynamic value) {
  if (value is num) return value.toInt();

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

bool _bool(dynamic value) {
  if (value is bool) return value;

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    return value.toLowerCase() == 'true';
  }

  return false;
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();

  if (value is DateTime) return value;

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}