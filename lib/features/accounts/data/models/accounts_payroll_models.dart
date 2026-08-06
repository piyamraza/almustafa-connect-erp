import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/payroll_profile_entity.dart';
import '../../domain/entities/payroll_record_entity.dart';

DateTime _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

int _int(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

T _enum<T extends Enum>(
  List<T> values,
  dynamic value,
  T fallback,
) {
  final raw = value?.toString();

  for (final item in values) {
    if (item.name == raw) {
      return item;
    }
  }

  return fallback;
}

class PayrollProfileModel extends PayrollProfileEntity {
  const PayrollProfileModel({
    required super.id,
    required super.employeeId,
    required super.employeeName,
    required super.employeeType,
    required super.basicSalary,
    required super.fixedAllowances,
    required super.fixedDeductions,
    required super.effectiveFrom,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PayrollProfileModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return PayrollProfileModel(
      id: map['id'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      employeeType: _enum(
        PayrollEmployeeType.values,
        map['employeeType'],
        PayrollEmployeeType.other,
      ),
      basicSalary: _int(map['basicSalary']),
      fixedAllowances: _int(map['fixedAllowances']),
      fixedDeductions: _int(map['fixedDeductions']),
      effectiveFrom: _date(map['effectiveFrom']),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  factory PayrollProfileModel.fromEntity(
    PayrollProfileEntity entity,
  ) {
    return PayrollProfileModel(
      id: entity.id,
      employeeId: entity.employeeId,
      employeeName: entity.employeeName,
      employeeType: entity.employeeType,
      basicSalary: entity.basicSalary,
      fixedAllowances: entity.fixedAllowances,
      fixedDeductions: entity.fixedDeductions,
      effectiveFrom: entity.effectiveFrom,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeType': employeeType.name,
      'basicSalary': basicSalary,
      'fixedAllowances': fixedAllowances,
      'fixedDeductions': fixedDeductions,
      'effectiveFrom': effectiveFrom.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PayrollRecordModel extends PayrollRecordEntity {
  const PayrollRecordModel({
    required super.id,
    required super.employeeId,
    required super.employeeName,
    required super.payrollMonth,
    required super.basicSalary,
    required super.allowances,
    required super.deductions,
    required super.absenceDeduction,
    required super.advanceDeduction,
    required super.loanDeduction,
    required super.bonus,
    required super.grossSalary,
    required super.netSalary,
    required super.paymentStatus,
    required super.paymentMethod,
    required super.referenceNumber,
    required super.remarks,
    required super.generatedBy,
    required super.approvedBy,
    required super.paidBy,
    required super.createdAt,
    required super.updatedAt,
    super.employeeType,
    super.paymentDate,
    super.approvedAt,
  });

  factory PayrollRecordModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return PayrollRecordModel(
      id: map['id'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      employeeType: _enum(
        PayrollEmployeeType.values,
        map['employeeType'],
        PayrollEmployeeType.teacher,
      ),
      payrollMonth: _date(map['payrollMonth']),
      basicSalary: _int(map['basicSalary']),
      allowances: _int(map['allowances']),
      deductions: _int(map['deductions']),
      absenceDeduction: _int(map['absenceDeduction']),
      advanceDeduction: _int(map['advanceDeduction']),
      loanDeduction: _int(map['loanDeduction']),
      bonus: _int(map['bonus']),
      grossSalary: _int(map['grossSalary']),
      netSalary: _int(map['netSalary']),
      paymentStatus: _enum(
        PayrollPaymentStatus.values,
        map['paymentStatus'],
        PayrollPaymentStatus.draft,
      ),
      paymentDate: map['paymentDate'] == null
          ? null
          : _date(map['paymentDate']),
      paymentMethod: map['paymentMethod'] as String? ?? '',
      referenceNumber:
          map['referenceNumber'] as String? ?? '',
      remarks: map['remarks'] as String? ?? '',
      generatedBy: map['generatedBy'] as String? ?? '',
      approvedBy: map['approvedBy'] as String? ?? '',
      approvedAt: map['approvedAt'] == null
          ? null
          : _date(map['approvedAt']),
      paidBy: map['paidBy'] as String? ?? '',
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  factory PayrollRecordModel.fromEntity(
    PayrollRecordEntity entity,
  ) {
    return PayrollRecordModel(
      id: entity.id,
      employeeId: entity.employeeId,
      employeeName: entity.employeeName,
      employeeType: entity.employeeType,
      payrollMonth: entity.payrollMonth,
      basicSalary: entity.basicSalary,
      allowances: entity.allowances,
      deductions: entity.deductions,
      absenceDeduction: entity.absenceDeduction,
      advanceDeduction: entity.advanceDeduction,
      loanDeduction: entity.loanDeduction,
      bonus: entity.bonus,
      grossSalary: entity.grossSalary,
      netSalary: entity.netSalary,
      paymentStatus: entity.paymentStatus,
      paymentDate: entity.paymentDate,
      paymentMethod: entity.paymentMethod,
      referenceNumber: entity.referenceNumber,
      remarks: entity.remarks,
      generatedBy: entity.generatedBy,
      approvedBy: entity.approvedBy,
      approvedAt: entity.approvedAt,
      paidBy: entity.paidBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeType': employeeType.name,
      'payrollMonth': payrollMonth.toIso8601String(),
      'basicSalary': basicSalary,
      'allowances': allowances,
      'deductions': deductions,
      'absenceDeduction': absenceDeduction,
      'advanceDeduction': advanceDeduction,
      'loanDeduction': loanDeduction,
      'bonus': bonus,
      'grossSalary': grossSalary,
      'netSalary': netSalary,
      'paymentStatus': paymentStatus.name,
      'paymentDate': paymentDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'remarks': remarks,
      'generatedBy': generatedBy,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'paidBy': paidBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}