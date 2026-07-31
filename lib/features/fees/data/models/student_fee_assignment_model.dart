import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/student_fee_assignment_entity.dart';

class StudentFeeAssignmentModel extends StudentFeeAssignmentEntity {
  const StudentFeeAssignmentModel({
    required super.id,
    required super.studentId,
    required super.studentName,
    required super.admissionNo,
    required super.classId,
    required super.sectionId,
    required super.academicSession,
    required super.feeStructureId,
    required super.feeStructureLabel,
    required super.baseMonthlyTuitionFee,
    required super.baseTransportFee,
    required super.baseOtherMonthlyCharges,
    required super.baseAdmissionFee,
    required super.baseAnnualCharges,
    required super.discountType,
    required super.discountValue,
    required super.scholarshipAmount,
    required super.siblingDiscountAmount,
    required super.transportEnabled,
    required super.customMonthlyTuitionFee,
    required super.admissionFeeWaived,
    required super.effectiveFrom,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StudentFeeAssignmentModel.fromEntity(
    StudentFeeAssignmentEntity entity,
  ) {
    return StudentFeeAssignmentModel(
      id: entity.id,
      studentId: entity.studentId,
      studentName: entity.studentName,
      admissionNo: entity.admissionNo,
      classId: entity.classId,
      sectionId: entity.sectionId,
      academicSession: entity.academicSession,
      feeStructureId: entity.feeStructureId,
      feeStructureLabel: entity.feeStructureLabel,
      baseMonthlyTuitionFee: entity.baseMonthlyTuitionFee,
      baseTransportFee: entity.baseTransportFee,
      baseOtherMonthlyCharges: entity.baseOtherMonthlyCharges,
      baseAdmissionFee: entity.baseAdmissionFee,
      baseAnnualCharges: entity.baseAnnualCharges,
      discountType: entity.discountType,
      discountValue: entity.discountValue,
      scholarshipAmount: entity.scholarshipAmount,
      siblingDiscountAmount: entity.siblingDiscountAmount,
      transportEnabled: entity.transportEnabled,
      customMonthlyTuitionFee: entity.customMonthlyTuitionFee,
      admissionFeeWaived: entity.admissionFeeWaived,
      effectiveFrom: entity.effectiveFrom,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory StudentFeeAssignmentModel.fromMap(Map<String, dynamic> map) {
    return StudentFeeAssignmentModel(
      id: map['id'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      admissionNo: map['admissionNo'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      feeStructureId: map['feeStructureId'] as String? ?? '',
      feeStructureLabel: map['feeStructureLabel'] as String? ?? '',
      baseMonthlyTuitionFee:
          (map['baseMonthlyTuitionFee'] as num?)?.toDouble() ?? 0,
      baseTransportFee: (map['baseTransportFee'] as num?)?.toDouble() ?? 0,
      baseOtherMonthlyCharges:
          (map['baseOtherMonthlyCharges'] as num?)?.toDouble() ?? 0,
      baseAdmissionFee: (map['baseAdmissionFee'] as num?)?.toDouble() ?? 0,
      baseAnnualCharges: (map['baseAnnualCharges'] as num?)?.toDouble() ?? 0,
      discountType: FeeDiscountType.values.firstWhere(
        (item) => item.name == map['discountType'],
        orElse: () => FeeDiscountType.none,
      ),
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0,
      scholarshipAmount: (map['scholarshipAmount'] as num?)?.toDouble() ?? 0,
      siblingDiscountAmount:
          (map['siblingDiscountAmount'] as num?)?.toDouble() ?? 0,
      transportEnabled: map['transportEnabled'] as bool? ?? false,
      customMonthlyTuitionFee: (map['customMonthlyTuitionFee'] as num?)
          ?.toDouble(),
      admissionFeeWaived: map['admissionFeeWaived'] as bool? ?? false,
      effectiveFrom: _date(map['effectiveFrom']),
      isActive: map['isActive'] as bool? ?? true,
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
    'feeStructureId': feeStructureId,
    'feeStructureLabel': feeStructureLabel,
    'baseMonthlyTuitionFee': baseMonthlyTuitionFee,
    'baseTransportFee': baseTransportFee,
    'baseOtherMonthlyCharges': baseOtherMonthlyCharges,
    'baseAdmissionFee': baseAdmissionFee,
    'baseAnnualCharges': baseAnnualCharges,
    'discountType': discountType.name,
    'discountValue': discountValue,
    'scholarshipAmount': scholarshipAmount,
    'siblingDiscountAmount': siblingDiscountAmount,
    'transportEnabled': transportEnabled,
    'customMonthlyTuitionFee': customMonthlyTuitionFee,
    'admissionFeeWaived': admissionFeeWaived,
    'effectiveFrom': Timestamp.fromDate(effectiveFrom),
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
