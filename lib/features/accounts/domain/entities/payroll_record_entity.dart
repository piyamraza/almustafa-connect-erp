import 'package:equatable/equatable.dart';

enum PayrollPaymentStatus { draft, generated, approved, paid, cancelled }

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
    this.paymentDate,
    this.approvedAt,
  });

  final String id;
  final String employeeId;
  final String employeeName;
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

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
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
