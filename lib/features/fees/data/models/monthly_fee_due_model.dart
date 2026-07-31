import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/monthly_fee_due_entity.dart';

class MonthlyFeeDueModel extends MonthlyFeeDueEntity {
  const MonthlyFeeDueModel({
    required super.id,
    required super.studentId,
    required super.studentName,
    required super.admissionNo,
    required super.classId,
    required super.sectionId,
    required super.academicSession,
    required super.feeAssignmentId,
    required super.month,
    required super.year,
    required super.dueDate,
    required super.tuitionFee,
    required super.transportFee,
    required super.otherMonthlyCharges,
    required super.discountAmount,
    required super.scholarshipAmount,
    required super.siblingDiscountAmount,
    required super.previousArrears,
    required super.advanceAdjustment,
    required super.netPayable,
    required super.paidAmount,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MonthlyFeeDueModel.fromEntity(MonthlyFeeDueEntity entity) {
    return MonthlyFeeDueModel(
      id: entity.id,
      studentId: entity.studentId,
      studentName: entity.studentName,
      admissionNo: entity.admissionNo,
      classId: entity.classId,
      sectionId: entity.sectionId,
      academicSession: entity.academicSession,
      feeAssignmentId: entity.feeAssignmentId,
      month: entity.month,
      year: entity.year,
      dueDate: entity.dueDate,
      tuitionFee: entity.tuitionFee,
      transportFee: entity.transportFee,
      otherMonthlyCharges: entity.otherMonthlyCharges,
      discountAmount: entity.discountAmount,
      scholarshipAmount: entity.scholarshipAmount,
      siblingDiscountAmount: entity.siblingDiscountAmount,
      previousArrears: entity.previousArrears,
      advanceAdjustment: entity.advanceAdjustment,
      netPayable: entity.netPayable,
      paidAmount: entity.paidAmount,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory MonthlyFeeDueModel.fromMap(Map<String, dynamic> map) {
    return MonthlyFeeDueModel(
      id: map['id'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      admissionNo: map['admissionNo'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      feeAssignmentId: map['feeAssignmentId'] as String? ?? '',
      month: (map['month'] as num?)?.toInt() ?? 1,
      year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
      dueDate: _date(map['dueDate']),
      tuitionFee: (map['tuitionFee'] as num?)?.toDouble() ?? 0,
      transportFee: (map['transportFee'] as num?)?.toDouble() ?? 0,
      otherMonthlyCharges:
          (map['otherMonthlyCharges'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0,
      scholarshipAmount: (map['scholarshipAmount'] as num?)?.toDouble() ?? 0,
      siblingDiscountAmount:
          (map['siblingDiscountAmount'] as num?)?.toDouble() ?? 0,
      previousArrears: (map['previousArrears'] as num?)?.toDouble() ?? 0,
      advanceAdjustment: (map['advanceAdjustment'] as num?)?.toDouble() ?? 0,
      netPayable: (map['netPayable'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      status: MonthlyFeeDueStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => MonthlyFeeDueStatus.unpaid,
      ),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'studentName': studentName,
    'admissionNo': admissionNo,
    'classId': classId,
    'sectionId': sectionId,
    'academicSession': academicSession,
    'feeAssignmentId': feeAssignmentId,
    'month': month,
    'year': year,
    'dueDate': Timestamp.fromDate(dueDate),
    'tuitionFee': tuitionFee,
    'transportFee': transportFee,
    'otherMonthlyCharges': otherMonthlyCharges,
    'discountAmount': discountAmount,
    'scholarshipAmount': scholarshipAmount,
    'siblingDiscountAmount': siblingDiscountAmount,
    'previousArrears': previousArrears,
    'advanceAdjustment': advanceAdjustment,
    'netPayable': netPayable,
    'paidAmount': paidAmount,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
