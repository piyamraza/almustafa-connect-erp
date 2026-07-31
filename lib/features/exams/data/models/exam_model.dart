import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/exam_entity.dart';

/// Firestore representation of an [ExamEntity].
class ExamModel extends ExamEntity {
  const ExamModel({
    required super.id,
    required super.name,
    required super.type,
    required super.academicSession,
    required super.classId,
    required super.sectionId,
    required super.subject,
    required super.examDate,
    required super.totalMarks,
    required super.passingMarks,
    required super.createdAt,
    super.startDate,
    super.endDate,
    super.resultDate,
    super.description,
    super.isActive,
  });

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return ExamModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: _examTypeFromValue(map['type']),
      academicSession: map['academicSession'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      examDate: _dateFromValue(map['examDate']) ?? now,
      totalMarks: _doubleFromValue(map['totalMarks']),
      passingMarks: _doubleFromValue(map['passingMarks']),
      createdAt: _dateFromValue(map['createdAt']) ?? now,
      startDate: _dateFromValue(map['startDate']),
      endDate: _dateFromValue(map['endDate']),
      resultDate: _dateFromValue(map['resultDate']),
      description: map['description'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  factory ExamModel.fromEntity(ExamEntity entity) {
    return ExamModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      academicSession: entity.academicSession,
      classId: entity.classId,
      sectionId: entity.sectionId,
      subject: entity.subject,
      examDate: entity.examDate,
      totalMarks: entity.totalMarks,
      passingMarks: entity.passingMarks,
      createdAt: entity.createdAt,
      startDate: entity.startDate,
      endDate: entity.endDate,
      resultDate: entity.resultDate,
      description: entity.description,
      isActive: entity.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'academicSession': academicSession,
      'classId': classId,
      'sectionId': sectionId,
      'subject': subject,
      'examDate': examDate.toIso8601String(),
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'resultDate': resultDate?.toIso8601String(),
      'description': description,
      'isActive': isActive,
    };
  }

  static ExamType _examTypeFromValue(dynamic value) {
    final typeName = value as String?;
    return ExamType.values.firstWhere(
      (type) => type.name == typeName,
      orElse: () => ExamType.monthly,
    );
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static double _doubleFromValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
