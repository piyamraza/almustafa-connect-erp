import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/academic_subject_entity.dart';

class AcademicSubjectModel extends AcademicSubjectEntity {
  const AcademicSubjectModel({
    required super.id,
    required super.classId,
    super.sectionId,
    required super.name,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AcademicSubjectModel.fromEntity(AcademicSubjectEntity value) {
    return AcademicSubjectModel(
      id: value.id,
      classId: value.classId,
      sectionId: value.sectionId,
      name: value.name,
      isActive: value.isActive,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

  factory AcademicSubjectModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return AcademicSubjectModel(
      id: map['id'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: _sectionId(map['sectionId']),
      name: map['name'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _date(map['createdAt']) ?? now,
      updatedAt: _date(map['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'sectionId': sectionId,
      'name': name,
      'nameKey': name.trim().toLowerCase(),
      'classSubjectKey': classSubjectKey,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return value is String ? DateTime.tryParse(value) : null;
  }

  static String? _sectionId(dynamic value) {
    final sectionId = value as String?;
    return sectionId == null || sectionId.trim().isEmpty ? null : sectionId;
  }
}
