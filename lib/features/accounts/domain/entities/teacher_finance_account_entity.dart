import 'package:equatable/equatable.dart';

enum TeacherFinanceType { advance, loan }

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
    this.closedAt,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final TeacherFinanceType financeType;
  final int principalAmount;
  final int monthlyRecoveryAmount;
  final int recoveredAmount;
  final int outstandingAmount;
  final DateTime issueDate;
  final DateTime recoveryStartMonth;
  final TeacherFinanceStatus status;
  final String approvedBy;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  bool get isActive =>
      status == TeacherFinanceStatus.active && outstandingAmount > 0;

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
    status,
    approvedBy,
    notes,
    createdAt,
    updatedAt,
    closedAt,
  ];
}
