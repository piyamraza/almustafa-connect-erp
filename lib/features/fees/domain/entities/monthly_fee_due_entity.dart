import 'package:equatable/equatable.dart';

enum MonthlyFeeDueStatus { unpaid, partiallyPaid, paid, cancelled }

class MonthlyFeeDueEntity extends Equatable {
  const MonthlyFeeDueEntity({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.classId,
    required this.sectionId,
    required this.academicSession,
    required this.feeAssignmentId,
    required this.month,
    required this.year,
    required this.dueDate,
    required this.tuitionFee,
    required this.transportFee,
    required this.otherMonthlyCharges,
    required this.discountAmount,
    required this.scholarshipAmount,
    required this.siblingDiscountAmount,
    required this.previousArrears,
    required this.advanceAdjustment,
    required this.netPayable,
    required this.paidAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String admissionNo;
  final String classId;
  final String sectionId;
  final String academicSession;
  final String feeAssignmentId;
  final int month;
  final int year;
  final DateTime dueDate;
  final double tuitionFee;
  final double transportFee;
  final double otherMonthlyCharges;
  final double discountAmount;
  final double scholarshipAmount;
  final double siblingDiscountAmount;
  final double previousArrears;
  final double advanceAdjustment;
  final double netPayable;
  final double paidAmount;
  final MonthlyFeeDueStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get monthKey => '$studentId|$year|${month.toString().padLeft(2, '0')}';

  double get outstandingAmount {
    final value = netPayable - paidAmount;
    return value < 0 ? 0 : value;
  }

  double get recurringGross => tuitionFee + transportFee + otherMonthlyCharges;

  double get totalDeductions =>
      discountAmount + scholarshipAmount + siblingDiscountAmount;

  @override
  List<Object> get props => [
    id,
    studentId,
    studentName,
    admissionNo,
    classId,
    sectionId,
    academicSession,
    feeAssignmentId,
    month,
    year,
    dueDate,
    tuitionFee,
    transportFee,
    otherMonthlyCharges,
    discountAmount,
    scholarshipAmount,
    siblingDiscountAmount,
    previousArrears,
    advanceAdjustment,
    netPayable,
    paidAmount,
    status,
    createdAt,
    updatedAt,
  ];
}
