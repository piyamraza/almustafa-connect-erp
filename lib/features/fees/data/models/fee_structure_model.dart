import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/fee_structure_entity.dart';

class FeeStructureModel extends FeeStructureEntity {
  const FeeStructureModel({
    required super.id,
    required super.academicSession,
    required super.classId,
    required super.className,
    required super.sectionId,
    required super.sectionName,
    required super.monthlyTuitionFee,
    required super.admissionFee,
    required super.annualCharges,
    required super.transportFee,
    required super.otherMonthlyCharges,
    required super.dueDay,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FeeStructureModel.fromEntity(FeeStructureEntity entity) {
    return FeeStructureModel(
      id: entity.id,
      academicSession: entity.academicSession,
      classId: entity.classId,
      className: entity.className,
      sectionId: entity.sectionId,
      sectionName: entity.sectionName,
      monthlyTuitionFee: entity.monthlyTuitionFee,
      admissionFee: entity.admissionFee,
      annualCharges: entity.annualCharges,
      transportFee: entity.transportFee,
      otherMonthlyCharges: entity.otherMonthlyCharges,
      dueDay: entity.dueDay,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory FeeStructureModel.fromMap(Map<String, dynamic> map) {
    return FeeStructureModel(
      id: map['id'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      sectionName: map['sectionName'] as String? ?? '',
      monthlyTuitionFee: (map['monthlyTuitionFee'] as num?)?.toDouble() ?? 0,
      admissionFee: (map['admissionFee'] as num?)?.toDouble() ?? 0,
      annualCharges: (map['annualCharges'] as num?)?.toDouble() ?? 0,
      transportFee: (map['transportFee'] as num?)?.toDouble() ?? 0,
      otherMonthlyCharges:
          (map['otherMonthlyCharges'] as num?)?.toDouble() ?? 0,
      dueDay: (map['dueDay'] as num?)?.toInt() ?? 10,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'academicSession': academicSession,
    'classId': classId,
    'className': className,
    'sectionId': sectionId,
    'sectionName': sectionName,
    'monthlyTuitionFee': monthlyTuitionFee,
    'admissionFee': admissionFee,
    'annualCharges': annualCharges,
    'transportFee': transportFee,
    'otherMonthlyCharges': otherMonthlyCharges,
    'dueDay': dueDay,
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
