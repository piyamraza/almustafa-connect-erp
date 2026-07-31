import 'package:equatable/equatable.dart';

enum StaffSalaryPaymentStatus {
  unpaid,
  paid,
}

enum StaffSalaryPaymentMethod {
  cash,
  bankTransfer,
  easypaisa,
  jazzCash,
  cheque,
  other,
}

class StaffSalaryEntity extends Equatable {
  const StaffSalaryEntity({
    required this.id,
    required this.staffId,
    required this.staffCode,
    required this.staffName,
    required this.designation,
    required this.salaryMonth,
    required this.basicSalary,
    required this.allowance,
    required this.deduction,
    required this.attendanceDeduction,
    required this.grossSalary,
    required this.netSalary,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.leaveDays,
    required this.paymentStatus,
    required this.paymentReference,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.paymentDate,
    this.paymentMethod,
  });

  final String id;

  /// Firestore document ID of the staff member.
  final String staffId;

  /// Readable staff code, for example STF123456.
  final String staffCode;

  final String staffName;
  final String designation;

  /// Always normalized to the first day of the selected month.
  final DateTime salaryMonth;

  final double basicSalary;
  final double allowance;
  final double deduction;
  final double attendanceDeduction;
  final double grossSalary;
  final double netSalary;

  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int leaveDays;

  final StaffSalaryPaymentStatus paymentStatus;
  final DateTime? paymentDate;
  final StaffSalaryPaymentMethod? paymentMethod;
  final String paymentReference;
  final String remarks;

  final DateTime createdAt;
  final DateTime updatedAt;

  int get totalMarkedDays {
    return presentDays + absentDays + lateDays + leaveDays;
  }

  bool get isPaid => paymentStatus == StaffSalaryPaymentStatus.paid;

  StaffSalaryEntity copyWith({
    String? id,
    String? staffId,
    String? staffCode,
    String? staffName,
    String? designation,
    DateTime? salaryMonth,
    double? basicSalary,
    double? allowance,
    double? deduction,
    double? attendanceDeduction,
    double? grossSalary,
    double? netSalary,
    int? presentDays,
    int? absentDays,
    int? lateDays,
    int? leaveDays,
    StaffSalaryPaymentStatus? paymentStatus,
    DateTime? paymentDate,
    StaffSalaryPaymentMethod? paymentMethod,
    String? paymentReference,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearPaymentDate = false,
    bool clearPaymentMethod = false,
  }) {
    return StaffSalaryEntity(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffCode: staffCode ?? this.staffCode,
      staffName: staffName ?? this.staffName,
      designation: designation ?? this.designation,
      salaryMonth: salaryMonth ?? this.salaryMonth,
      basicSalary: basicSalary ?? this.basicSalary,
      allowance: allowance ?? this.allowance,
      deduction: deduction ?? this.deduction,
      attendanceDeduction:
          attendanceDeduction ?? this.attendanceDeduction,
      grossSalary: grossSalary ?? this.grossSalary,
      netSalary: netSalary ?? this.netSalary,
      presentDays: presentDays ?? this.presentDays,
      absentDays: absentDays ?? this.absentDays,
      lateDays: lateDays ?? this.lateDays,
      leaveDays: leaveDays ?? this.leaveDays,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate:
          clearPaymentDate ? null : paymentDate ?? this.paymentDate,
      paymentMethod:
          clearPaymentMethod ? null : paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        staffId,
        staffCode,
        staffName,
        designation,
        salaryMonth,
        basicSalary,
        allowance,
        deduction,
        attendanceDeduction,
        grossSalary,
        netSalary,
        presentDays,
        absentDays,
        lateDays,
        leaveDays,
        paymentStatus,
        paymentDate,
        paymentMethod,
        paymentReference,
        remarks,
        createdAt,
        updatedAt,
      ];
}