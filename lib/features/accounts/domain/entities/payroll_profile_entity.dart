import 'package:equatable/equatable.dart';

enum PayrollEmployeeType { teacher, administrativeStaff, supportStaff, other }

class PayrollProfileEntity extends Equatable {
  const PayrollProfileEntity({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeType,
    required this.basicSalary,
    required this.fixedAllowances,
    required this.fixedDeductions,
    required this.effectiveFrom,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final PayrollEmployeeType employeeType;
  final int basicSalary;
  final int fixedAllowances;
  final int fixedDeductions;
  final DateTime effectiveFrom;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    employeeType,
    basicSalary,
    fixedAllowances,
    fixedDeductions,
    effectiveFrom,
    isActive,
    createdAt,
    updatedAt,
  ];
}
