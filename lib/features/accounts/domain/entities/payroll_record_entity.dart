import 'package:equatable/equatable.dart';

import 'payroll_profile_entity.dart';

enum PayrollPaymentStatus {
  draft,
  generated,
  approved,
  paid,
  cancelled,
}

class PayrollRecordEntity extends Equatable {
  const PayrollRecordEntity({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.payrollMonth,
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
    required this.absenceDeduction,
    required this.advanceDeduction,
    required this.loanDeduction,
    required this.bonus,
    required this.grossSalary,
    required this.netSalary,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.remarks,
    required this.generatedBy,
    required this.approvedBy,
    required this.paidBy,
    required this.createdAt,
    required this.updatedAt,
    this.employeeType = PayrollEmployeeType.teacher,
    this.paymentDate,
    this.approvedAt,
  });

  final String id;
  final String employeeId;
  final String employeeName;

  /// Identifies whether this payroll belongs to a teacher or staff member.
  ///
  /// The default remains teacher so existing payroll records and constructor
  /// calls remain backward compatible.
  final PayrollEmployeeType employeeType;

  final DateTime payrollMonth;
  final int basicSalary;
  final int allowances;
  final int deductions;
  final int absenceDeduction;
  final int advanceDeduction;
  final int loanDeduction;
  final int bonus;
  final int grossSalary;
  final int netSalary;
  final PayrollPaymentStatus paymentStatus;
  final DateTime? paymentDate;
  final String paymentMethod;
  final String referenceNumber;
  final String remarks;
  final String generatedBy;
  final String approvedBy;
  final DateTime? approvedAt;
  final String paidBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTeacher =>
      employeeType == PayrollEmployeeType.teacher;

  bool get isStaff =>
      employeeType != PayrollEmployeeType.teacher;

  PayrollRecordEntity copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    PayrollEmployeeType? employeeType,
    DateTime? payrollMonth,
    int? basicSalary,
    int? allowances,
    int? deductions,
    int? absenceDeduction,
    int? advanceDeduction,
    int? loanDeduction,
    int? bonus,
    int? grossSalary,
    int? netSalary,
    PayrollPaymentStatus? paymentStatus,
    DateTime? paymentDate,
    bool clearPaymentDate = false,
    String? paymentMethod,
    String? referenceNumber,
    String? remarks,
    String? generatedBy,
    String? approvedBy,
    DateTime? approvedAt,
    bool clearApprovedAt = false,
    String? paidBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PayrollRecordEntity(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeType: employeeType ?? this.employeeType,
      payrollMonth: payrollMonth ?? this.payrollMonth,
      basicSalary: basicSalary ?? this.basicSalary,
      allowances: allowances ?? this.allowances,
      deductions: deductions ?? this.deductions,
      absenceDeduction:
          absenceDeduction ?? this.absenceDeduction,
      advanceDeduction:
          advanceDeduction ?? this.advanceDeduction,
      loanDeduction:
          loanDeduction ?? this.loanDeduction,
      bonus: bonus ?? this.bonus,
      grossSalary: grossSalary ?? this.grossSalary,
      netSalary: netSalary ?? this.netSalary,
      paymentStatus:
          paymentStatus ?? this.paymentStatus,
      paymentDate: clearPaymentDate
          ? null
          : paymentDate ?? this.paymentDate,
      paymentMethod:
          paymentMethod ?? this.paymentMethod,
      referenceNumber:
          referenceNumber ?? this.referenceNumber,
      remarks: remarks ?? this.remarks,
      generatedBy: generatedBy ?? this.generatedBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: clearApprovedAt
          ? null
          : approvedAt ?? this.approvedAt,
      paidBy: paidBy ?? this.paidBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    employeeType,
    payrollMonth,
    basicSalary,
    allowances,
    deductions,
    absenceDeduction,
    advanceDeduction,
    loanDeduction,
    bonus,
    grossSalary,
    netSalary,
    paymentStatus,
    paymentDate,
    paymentMethod,
    referenceNumber,
    remarks,
    generatedBy,
    approvedBy,
    approvedAt,
    paidBy,
    createdAt,
    updatedAt,
  ];
}