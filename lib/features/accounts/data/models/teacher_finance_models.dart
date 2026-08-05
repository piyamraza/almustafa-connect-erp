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
    super.closedAt,
  });

  factory TeacherFinanceAccountModel.fromEntity(
    TeacherFinanceAccountEntity entity,
  ) {
    return TeacherFinanceAccountModel(
      id: entity.id,
      employeeId: entity.employeeId,
      employeeName: entity.employeeName,
      financeType: entity.financeType,
      principalAmount: entity.principalAmount,
      monthlyRecoveryAmount: entity.monthlyRecoveryAmount,
      recoveredAmount: entity.recoveredAmount,
      outstandingAmount: entity.outstandingAmount,
      issueDate: entity.issueDate,
      recoveryStartMonth: entity.recoveryStartMonth,
      status: entity.status,
      approvedBy: entity.approvedBy,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      closedAt: entity.closedAt,
    );
  }

  factory TeacherFinanceAccountModel.fromMap(Map<String, dynamic> map) {
    return TeacherFinanceAccountModel(
      id: map['id'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      financeType: TeacherFinanceType.values.firstWhere(
        (value) => value.name == map['financeType'],
        orElse: () => TeacherFinanceType.advance,
      ),
      principalAmount: _int(map['principalAmount']),
      monthlyRecoveryAmount: _int(map['monthlyRecoveryAmount']),
      recoveredAmount: _int(map['recoveredAmount']),
      outstandingAmount: _int(map['outstandingAmount']),
      issueDate: _date(map['issueDate']) ?? DateTime.now(),
      recoveryStartMonth: _date(map['recoveryStartMonth']) ?? DateTime.now(),
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'employeeId': employeeId,
    'employeeName': employeeName,
    'financeType': financeType.name,
    'principalAmount': principalAmount,
    'monthlyRecoveryAmount': monthlyRecoveryAmount,
    'recoveredAmount': recoveredAmount,
    'outstandingAmount': outstandingAmount,
    'issueDate': issueDate.toIso8601String(),
    'recoveryStartMonth': recoveryStartMonth.toIso8601String(),
    'status': status.name,
    'approvedBy': approvedBy,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'closedAt': closedAt?.toIso8601String(),
  };
}

class TeacherFinanceTransactionModel extends TeacherFinanceTransactionEntity {
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
      referenceNumber: entity.referenceNumber,
      notes: entity.notes,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
    );
  }

  factory TeacherFinanceTransactionModel.fromMap(Map<String, dynamic> map) {
    return TeacherFinanceTransactionModel(
      id: map['id'] as String? ?? '',
      accountId: map['accountId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      transactionType: TeacherFinanceTransactionType.values.firstWhere(
        (value) => value.name == map['transactionType'],
        orElse: () => TeacherFinanceTransactionType.adjustment,
      ),
      amount: _int(map['amount']),
      transactionDate: _date(map['transactionDate']) ?? DateTime.now(),
      payrollId: map['payrollId'] as String? ?? '',
      referenceNumber: map['referenceNumber'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'accountId': accountId,
    'employeeId': employeeId,
    'employeeName': employeeName,
    'transactionType': transactionType.name,
    'amount': amount,
    'transactionDate': transactionDate.toIso8601String(),
    'payrollId': payrollId,
    'referenceNumber': referenceNumber,
    'notes': notes,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
  };
}

int _int(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
