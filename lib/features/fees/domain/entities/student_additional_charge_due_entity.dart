import 'package:equatable/equatable.dart';
import 'additional_charge_entity.dart';

enum StudentAdditionalChargeDueStatus {
  unpaid,
  partiallyPaid,
  paid,
  waived,
  cancelled,
}

class StudentAdditionalChargeDueEntity extends Equatable {
  const StudentAdditionalChargeDueEntity({
    required this.id,
    required this.chargeId,
    required this.chargeTitle,
    required this.chargeCategory,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.classId,
    required this.sectionId,
    required this.academicSession,
    required this.amount,
    required this.discountAmount,
    required this.waivedAmount,
    required this.netPayable,
    required this.paidAmount,
    required this.dueDate,
    required this.status,
    required this.notes,
    required this.generatedAt,
    required this.updatedAt,
  });

  final String id, chargeId, chargeTitle, studentId, studentName, admissionNo;
  final String classId, sectionId, academicSession, notes;
  final AdditionalChargeCategory chargeCategory;
  final double amount, discountAmount, waivedAmount, netPayable, paidAmount;
  final DateTime dueDate, generatedAt, updatedAt;
  final StudentAdditionalChargeDueStatus status;
  double get outstandingAmount =>
      (netPayable - paidAmount).clamp(0, double.infinity);

  @override
  List<Object> get props => [
    id,
    chargeId,
    chargeTitle,
    chargeCategory,
    studentId,
    studentName,
    admissionNo,
    classId,
    sectionId,
    academicSession,
    amount,
    discountAmount,
    waivedAmount,
    netPayable,
    paidAmount,
    dueDate,
    status,
    notes,
    generatedAt,
    updatedAt,
  ];
}
