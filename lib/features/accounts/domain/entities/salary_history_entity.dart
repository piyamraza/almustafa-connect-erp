import 'package:equatable/equatable.dart';

import 'payroll_profile_entity.dart';

class PayrollEmployeeEntity extends Equatable {
  const PayrollEmployeeEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.monthlySalary,
    required this.joiningDate,
  });

  final String id;
  final String code;
  final String name;
  final PayrollEmployeeType type;
  final int monthlySalary;
  final DateTime joiningDate;

  @override
  List<Object?> get props => [id, code, name, type, monthlySalary, joiningDate];
}

class SalaryHistoryEntity extends Equatable {
  const SalaryHistoryEntity({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.employeeType,
    required this.previousSalary,
    required this.incrementAmount,
    required this.newSalary,
    required this.effectiveAt,
    required this.changedBy,
    required this.changeType,
    required this.createdAt,
  });

  final String id;
  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final PayrollEmployeeType employeeType;
  final int previousSalary;
  final int incrementAmount;
  final int newSalary;
  final DateTime effectiveAt;
  final String changedBy;
  final String changeType;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeCode,
    employeeName,
    employeeType,
    previousSalary,
    incrementAmount,
    newSalary,
    effectiveAt,
    changedBy,
    changeType,
    createdAt,
  ];
}

class SalaryIncrementRequest {
  const SalaryIncrementRequest({
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.employeeType,
    required this.currentSalary,
    required this.incrementAmount,
  });

  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final PayrollEmployeeType employeeType;
  final int currentSalary;
  final int incrementAmount;
}
