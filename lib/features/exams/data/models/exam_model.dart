import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/exam_entity.dart';

/// Firestore representation of the examination master record.
class ExamModel extends ExamEntity {
  const ExamModel({
    required super.id,
    required super.name,
    required super.type,
    required super.academicSession,
    required super.createdAt,
    super.academicYearId,
    super.startDate,
    super.endDate,
    super.resultDate,
    super.description,
    super.status,
    super.isActive,
    super.createdBy,
    super.updatedAt,
    super.classId,
    super.sectionId,
    super.subject,
    super.examDate,
    super.totalMarks,
    super.passingMarks,
  });

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    final createdAt = _dateFromValue(map['createdAt']) ?? now;
    final startDate =
        _dateFromValue(map['startDate']) ?? _dateFromValue(map['examDate']);

    return ExamModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: _examTypeFromValue(map['type']),
      academicSession: map['academicSession'] as String? ?? '',
      academicYearId: map['academicYearId'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: _dateFromValue(map['updatedAt']),
      startDate: startDate,
      endDate: _dateFromValue(map['endDate']) ?? startDate,
      resultDate: _dateFromValue(map['resultDate']) ?? startDate,
      description: map['description'] as String? ?? '',
      status: _statusFromMap(map),
      createdBy: map['createdBy'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      examDate: _dateFromValue(map['examDate']) ?? startDate ?? createdAt,
      totalMarks: _doubleFromValue(map['totalMarks']),
      passingMarks: _doubleFromValue(map['passingMarks']),
    );
  }

  factory ExamModel.fromEntity(ExamEntity entity) {
    return ExamModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      academicSession: entity.academicSession,
      academicYearId: entity.academicYearId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      startDate: entity.startDate,
      endDate: entity.endDate,
      resultDate: entity.resultDate,
      description: entity.description,
      status: entity.status,
      createdBy: entity.createdBy,
      classId: entity.classId,
      sectionId: entity.sectionId,
      subject: entity.subject,
      examDate: entity.examDate,
      totalMarks: entity.totalMarks,
      passingMarks: entity.passingMarks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'academicSession': academicSession,
      'academicYearId': academicYearId,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'resultDate': resultDate?.toIso8601String(),
      'description': description,
      'status': status.name,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'schemaVersion': 2,
    };
  }

  static ExamType _examTypeFromValue(dynamic value) {
    final typeName = value as String?;
    return ExamType.values.firstWhere(
      (type) => type.name == typeName,
      orElse: () => ExamType.monthly,
    );
  }

  static ExamWorkflowStatus _statusFromMap(Map<String, dynamic> map) {
    final value = map['status'] as String?;
    if (value != null) {
      return ExamWorkflowStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => ExamWorkflowStatus.draft,
      );
    }

    return (map['isActive'] as bool? ?? true)
        ? ExamWorkflowStatus.active
        : ExamWorkflowStatus.draft;
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double _doubleFromValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}