import 'dart:convert';

import 'package:equatable/equatable.dart';

class ExamMarkEntity extends Equatable {
  const ExamMarkEntity({
    required this.id,
    required this.entryKey,
    required this.examId,
    required this.examName,
    required this.academicSession,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.subjectId,
    required this.subjectName,
    required this.studentId,
    required this.rollNumber,
    required this.studentName,
    required this.admissionNo,
    required this.obtainedMarks,
    required this.isAbsent,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String entryKey;
  final String examId;
  final String examName;
  final String academicSession;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final String subjectId;
  final String subjectName;
  final String studentId;
  final String rollNumber;
  final String studentName;
  final String admissionNo;
  final double obtainedMarks;
  final bool isAbsent;
  final String remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  static String entryKeyFor({
    required String examId,
    required String classId,
    required String sectionId,
    required String subjectId,
  }) {
    return '$examId|$classId|$sectionId|$subjectId';
  }

  static String documentIdFor({
    required String examId,
    required String classId,
    required String sectionId,
    required String subjectId,
    required String studentId,
  }) {
    final identity = '$examId|$classId|$sectionId|$subjectId|$studentId';
    return base64Url.encode(utf8.encode(identity)).replaceAll('=', '');
  }

  ExamMarkEntity copyWith({
    String? id,
    String? entryKey,
    String? examId,
    String? examName,
    String? academicSession,
    String? classId,
    String? className,
    String? sectionId,
    String? sectionName,
    String? subjectId,
    String? subjectName,
    String? studentId,
    String? rollNumber,
    String? studentName,
    String? admissionNo,
    double? obtainedMarks,
    bool? isAbsent,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamMarkEntity(
      id: id ?? this.id,
      entryKey: entryKey ?? this.entryKey,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      academicSession: academicSession ?? this.academicSession,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      studentId: studentId ?? this.studentId,
      rollNumber: rollNumber ?? this.rollNumber,
      studentName: studentName ?? this.studentName,
      admissionNo: admissionNo ?? this.admissionNo,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      isAbsent: isAbsent ?? this.isAbsent,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        entryKey,
        examId,
        examName,
        academicSession,
        classId,
        className,
        sectionId,
        sectionName,
        subjectId,
        subjectName,
        studentId,
        rollNumber,
        studentName,
        admissionNo,
        obtainedMarks,
        isAbsent,
        remarks,
        createdAt,
        updatedAt,
      ];
}
