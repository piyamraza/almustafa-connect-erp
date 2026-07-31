import '../../domain/entities/staff_salary_entity.dart';

class StaffSalaryModel extends StaffSalaryEntity {
  const StaffSalaryModel({
    required super.id,
    required super.staffId,
    required super.staffCode,
    required super.staffName,
    required super.designation,
    required super.salaryMonth,
    required super.basicSalary,
    required super.allowance,
    required super.deduction,
    required super.attendanceDeduction,
    required super.grossSalary,
    required super.netSalary,
    required super.presentDays,
    required super.absentDays,
    required super.lateDays,
    required super.leaveDays,
    required super.paymentStatus,
    required super.paymentReference,
    required super.remarks,
    required super.createdAt,
    required super.updatedAt,
    super.paymentDate,
    super.paymentMethod,
  });

  factory StaffSalaryModel.fromEntity(
    StaffSalaryEntity entity,
  ) {
    return StaffSalaryModel(
      id: entity.id,
      staffId: entity.staffId,
      staffCode: entity.staffCode,
      staffName: entity.staffName,
      designation: entity.designation,
      salaryMonth: entity.salaryMonth,
      basicSalary: entity.basicSalary,
      allowance: entity.allowance,
      deduction: entity.deduction,
      attendanceDeduction: entity.attendanceDeduction,
      grossSalary: entity.grossSalary,
      netSalary: entity.netSalary,
      presentDays: entity.presentDays,
      absentDays: entity.absentDays,
      lateDays: entity.lateDays,
      leaveDays: entity.leaveDays,
      paymentStatus: entity.paymentStatus,
      paymentDate: entity.paymentDate,
      paymentMethod: entity.paymentMethod,
      paymentReference: entity.paymentReference,
      remarks: entity.remarks,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory StaffSalaryModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return StaffSalaryModel(
      id: map['id'] as String? ?? '',
      staffId: map['staffId'] as String? ?? '',
      staffCode: map['staffCode'] as String? ?? '',
      staffName: map['staffName'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
      salaryMonth: _parseDate(map['salaryMonth']),
      basicSalary: _parseDouble(map['basicSalary']),
      allowance: _parseDouble(map['allowance']),
      deduction: _parseDouble(map['deduction']),
      attendanceDeduction:
          _parseDouble(map['attendanceDeduction']),
      grossSalary: _parseDouble(map['grossSalary']),
      netSalary: _parseDouble(map['netSalary']),
      presentDays: _parseInt(map['presentDays']),
      absentDays: _parseInt(map['absentDays']),
      lateDays: _parseInt(map['lateDays']),
      leaveDays: _parseInt(map['leaveDays']),
      paymentStatus: StaffSalaryPaymentStatus.values.firstWhere(
        (status) => status.name == map['paymentStatus'],
        orElse: () => StaffSalaryPaymentStatus.unpaid,
      ),
      paymentDate: _parseNullableDate(map['paymentDate']),
      paymentMethod: _parsePaymentMethod(map['paymentMethod']),
      paymentReference:
          map['paymentReference'] as String? ?? '',
      remarks: map['remarks'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staffId': staffId,
      'staffCode': staffCode,
      'staffName': staffName,
      'designation': designation,
      'salaryMonth': salaryMonth.toIso8601String(),
      'basicSalary': basicSalary,
      'allowance': allowance,
      'deduction': deduction,
      'attendanceDeduction': attendanceDeduction,
      'grossSalary': grossSalary,
      'netSalary': netSalary,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateDays': lateDays,
      'leaveDays': leaveDays,
      'paymentStatus': paymentStatus.name,
      'paymentDate': paymentDate?.toIso8601String(),
      'paymentMethod': paymentMethod?.name,
      'paymentReference': paymentReference,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static int _parseInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static DateTime _parseDate(dynamic value) {
    return _parseNullableDate(value) ?? DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static StaffSalaryPaymentMethod? _parsePaymentMethod(
    dynamic value,
  ) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    for (final method in StaffSalaryPaymentMethod.values) {
      if (method.name == value) {
        return method;
      }
    }

    return null;
  }
}