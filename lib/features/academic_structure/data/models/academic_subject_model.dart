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
    super.useComponentsInTimetable = false,
    super.useComponentsInAttendance = false,
    super.useComponentsInHomework = false,
    super.useComponentsInExamination = true,
    super.useComponentsInReportCard = true,
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
      useComponentsInTimetable: value.useComponentsInTimetable,
      useComponentsInAttendance: value.useComponentsInAttendance,
      useComponentsInHomework: value.useComponentsInHomework,
      useComponentsInExamination: value.useComponentsInExamination,
      useComponentsInReportCard: value.useComponentsInReportCard,
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
      useComponentsInTimetable: map['useComponentsInTimetable'] as bool? ?? false,
      useComponentsInAttendance: map['useComponentsInAttendance'] as bool? ?? false,
      useComponentsInHomework: map['useComponentsInHomework'] as bool? ?? false,
      useComponentsInExamination: map['useComponentsInExamination'] as bool? ?? true,
      useComponentsInReportCard: map['useComponentsInReportCard'] as bool? ?? true,
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
      'useComponentsInTimetable': useComponentsInTimetable,
      'useComponentsInAttendance': useComponentsInAttendance,
      'useComponentsInHomework': useComponentsInHomework,
      'useComponentsInExamination': useComponentsInExamination,
      'useComponentsInReportCard': useComponentsInReportCard,
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
