import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/exam_subject_setup_entity.dart';

class ExamSubjectSetupModel extends ExamSubjectSetupEntity {
  const ExamSubjectSetupModel({
    required super.id,
    required super.examId,
    required super.examName,
    required super.academicSession,
    required super.classId,
    required super.className,
    required super.sectionId,
    required super.sectionName,
    required super.subjectId,
    required super.subjectName,
    required super.totalMarks,
    required super.passingMarks,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.academicYearId,
    super.theoryMarks,
    super.practicalMarks,
    super.internalAssessmentMarks,
    super.displayOrder,
    super.componentTotalMarks,
    super.componentPassingMarks,
  });

  factory ExamSubjectSetupModel.fromEntity(ExamSubjectSetupEntity entity) {
    return ExamSubjectSetupModel(
      id: entity.id,
      examId: entity.examId,
      examName: entity.examName,
      academicSession: entity.academicSession,
      academicYearId: entity.academicYearId,
      classId: entity.classId,
      className: entity.className,
      sectionId: entity.sectionId,
      sectionName: entity.sectionName,
      subjectId: entity.subjectId,
      subjectName: entity.subjectName,
      totalMarks: entity.totalMarks,
      passingMarks: entity.passingMarks,
      theoryMarks: entity.theoryMarks,
      practicalMarks: entity.practicalMarks,
      internalAssessmentMarks: entity.internalAssessmentMarks,
      displayOrder: entity.displayOrder,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      componentTotalMarks: entity.componentTotalMarks,
      componentPassingMarks: entity.componentPassingMarks,
    );
  }

  factory ExamSubjectSetupModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return ExamSubjectSetupModel(
      id: map['id'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      examName: map['examName'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      academicYearId: map['academicYearId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      sectionName: map['sectionName'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      totalMarks: _number(map['totalMarks']),
      passingMarks: _number(map['passingMarks']),
      theoryMarks: _number(map['theoryMarks']),
      practicalMarks: _number(map['practicalMarks']),
      internalAssessmentMarks: _number(map['internalAssessmentMarks']),
      displayOrder: _integer(map['displayOrder']),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _date(map['createdAt']) ?? now,
      updatedAt: _date(map['updatedAt']) ?? now,
      componentTotalMarks: _numberMap(map['componentTotalMarks']),
      componentPassingMarks: _numberMap(map['componentPassingMarks']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examId': examId,
      'examName': examName,
      'academicSession': academicSession,
      'academicYearId': academicYearId,
      'classId': classId,
      'className': className,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'uniqueKey': uniqueKey,
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'theoryMarks': theoryMarks,
      'practicalMarks': practicalMarks,
      'internalAssessmentMarks': internalAssessmentMarks,
      'componentTotalMarks': componentTotalMarks,
      'componentPassingMarks': componentPassingMarks,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'schemaVersion': 3,
    };
  }

  static Map<String, double> _numberMap(dynamic value) {
    if (value is! Map) return const {};
    return Map.unmodifiable({
      for (final entry in value.entries)
        entry.key.toString(): _number(entry.value),
    });
  }

  static double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _integer(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
