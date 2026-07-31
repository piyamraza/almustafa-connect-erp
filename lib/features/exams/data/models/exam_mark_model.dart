import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/exam_mark_entity.dart';

class ExamMarkModel extends ExamMarkEntity {
  const ExamMarkModel({
    required super.id,
    required super.entryKey,
    required super.examId,
    required super.examName,
    required super.academicSession,
    required super.classId,
    required super.className,
    required super.sectionId,
    required super.sectionName,
    required super.subjectId,
    required super.subjectName,
    required super.studentId,
    required super.rollNumber,
    required super.studentName,
    required super.admissionNo,
    required super.obtainedMarks,
    required super.isAbsent,
    required super.remarks,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ExamMarkModel.fromEntity(ExamMarkEntity value) {
    return ExamMarkModel(
      id: value.id,
      entryKey: value.entryKey,
      examId: value.examId,
      examName: value.examName,
      academicSession: value.academicSession,
      classId: value.classId,
      className: value.className,
      sectionId: value.sectionId,
      sectionName: value.sectionName,
      subjectId: value.subjectId,
      subjectName: value.subjectName,
      studentId: value.studentId,
      rollNumber: value.rollNumber,
      studentName: value.studentName,
      admissionNo: value.admissionNo,
      obtainedMarks: value.obtainedMarks,
      isAbsent: value.isAbsent,
      remarks: value.remarks,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

  factory ExamMarkModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return ExamMarkModel(
      id: map['id'] as String? ?? '',
      entryKey: map['entryKey'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      examName: map['examName'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      sectionName: map['sectionName'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      rollNumber: map['rollNumber'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      admissionNo: map['admissionNo'] as String? ?? '',
      obtainedMarks: _number(map['obtainedMarks']),
      isAbsent: map['isAbsent'] as bool? ?? false,
      remarks: map['remarks'] as String? ?? '',
      createdAt: _date(map['createdAt']) ?? now,
      updatedAt: _date(map['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entryKey': entryKey,
      'examId': examId,
      'examName': examName,
      'academicSession': academicSession,
      'classId': classId,
      'className': className,
      'sectionId': sectionId,
      'sectionName': sectionName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'studentId': studentId,
      'rollNumber': rollNumber,
      'studentName': studentName,
      'admissionNo': admissionNo,
      'obtainedMarks': obtainedMarks,
      'isAbsent': isAbsent,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static double _number(dynamic value) {
    return value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return value is String ? DateTime.tryParse(value) : null;
  }
}
