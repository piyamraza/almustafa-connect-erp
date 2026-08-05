import 'package:equatable/equatable.dart';

enum TeacherFinanceTransactionType {
  disbursement,
  payrollRecovery,
  manualRecovery,
  adjustment,
  cancellation,
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
  });

  final String id;
  final String accountId;
  final String employeeId;
  final String employeeName;
  final TeacherFinanceTransactionType transactionType;
  final int amount;
  final DateTime transactionDate;
  final String payrollId;
  final String referenceNumber;
  final String notes;
  final String createdBy;
  final DateTime createdAt;

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
    referenceNumber,
    notes,
    createdBy,
    createdAt,
  ];
}
