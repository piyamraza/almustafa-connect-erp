import 'package:equatable/equatable.dart';

enum FeeDiscountType { none, fixed, percentage }

class StudentFeeAssignmentEntity extends Equatable {
  const StudentFeeAssignmentEntity({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.classId,
    required this.sectionId,
    required this.academicSession,
    required this.feeStructureId,
    required this.feeStructureLabel,
    required this.baseMonthlyTuitionFee,
    required this.baseTransportFee,
    required this.baseOtherMonthlyCharges,
    required this.baseAdmissionFee,
    required this.baseAnnualCharges,
    required this.discountType,
    required this.discountValue,
    required this.scholarshipAmount,
    required this.siblingDiscountAmount,
    required this.transportEnabled,
    required this.customMonthlyTuitionFee,
    required this.admissionFeeWaived,
    required this.effectiveFrom,
    required this.isActive,
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
  final String feeStructureId;
  final String feeStructureLabel;
  final double baseMonthlyTuitionFee;
  final double baseTransportFee;
  final double baseOtherMonthlyCharges;
  final double baseAdmissionFee;
  final double baseAnnualCharges;
  final FeeDiscountType discountType;
  final double discountValue;
  final double scholarshipAmount;
  final double siblingDiscountAmount;
  final bool transportEnabled;
  final double? customMonthlyTuitionFee;
  final bool admissionFeeWaived;
  final DateTime effectiveFrom;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get tuitionFee => customMonthlyTuitionFee ?? baseMonthlyTuitionFee;

  double get discountAmount {
    if (discountType == FeeDiscountType.fixed) {
      return discountValue;
    }
    if (discountType == FeeDiscountType.percentage) {
      return tuitionFee * (discountValue / 100);
    }
    return 0;
  }

  double get monthlyPayable {
    final gross =
        tuitionFee +
        (transportEnabled ? baseTransportFee : 0) +
        baseOtherMonthlyCharges;
    final deductions =
        discountAmount + scholarshipAmount + siblingDiscountAmount;
    final value = gross - deductions;
    return value < 0 ? 0 : value;
  }

  double get admissionFeePayable => admissionFeeWaived ? 0 : baseAdmissionFee;

  @override
  List<Object?> get props => [
    id,
    studentId,
    studentName,
    admissionNo,
    classId,
    sectionId,
    academicSession,
    feeStructureId,
    feeStructureLabel,
    baseMonthlyTuitionFee,
    baseTransportFee,
    baseOtherMonthlyCharges,
    baseAdmissionFee,
    baseAnnualCharges,
    discountType,
    discountValue,
    scholarshipAmount,
    siblingDiscountAmount,
    transportEnabled,
    customMonthlyTuitionFee,
    admissionFeeWaived,
    effectiveFrom,
    isActive,
    createdAt,
    updatedAt,
  ];
}
