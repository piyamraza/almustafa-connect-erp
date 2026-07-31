import 'dart:convert';

import 'package:equatable/equatable.dart';

enum ResultStatus { draft, published, locked, unpublished }

class SubjectResultEntity extends Equatable {
  const SubjectResultEntity({
    required this.subjectId,
    required this.subjectName,
    required this.totalMarks,
    required this.obtainedMarks,
    required this.isAbsent,
    required this.isPassed,
    required this.remarks,
  });

  final String subjectId;
  final String subjectName;
  final double totalMarks;
  final double obtainedMarks;
  final bool isAbsent;
  final bool isPassed;
  final String remarks;

  @override
  List<Object?> get props => [
        subjectId,
        subjectName,
        totalMarks,
        obtainedMarks,
        isAbsent,
        isPassed,
        remarks,
      ];
}

class ExamResultEntity extends Equatable {
  const ExamResultEntity({
    required this.id,
    required this.examId,
    required this.examName,
    required this.academicSession,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.admissionNo,
    required this.subjectResults,
    required this.grandTotalMarks,
    required this.grandObtainedMarks,
    required this.percentage,
    required this.grade,
    required this.isPassed,
    required this.classPosition,
    required this.sectionPosition,
    required this.overallRank,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.principalRemarks = '',
  });

  final String id;
  final String examId;
  final String examName;
  final String academicSession;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String admissionNo;
  final List<SubjectResultEntity> subjectResults;
  final double grandTotalMarks;
  final double grandObtainedMarks;
  final double percentage;
  final String grade;
  final bool isPassed;
  final int classPosition;
  final int sectionPosition;
  final int overallRank;
  final ResultStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final String principalRemarks;

  static String documentIdFor({
    required String examId,
    required String classId,
    required String sectionId,
    required String studentId,
  }) {
    final identity = '$examId|$classId|$sectionId|$studentId';
    return base64Url.encode(utf8.encode(identity)).replaceAll('=', '');
  }

  ExamResultEntity copyWith({
    String? id,
    String? examId,
    String? examName,
    String? academicSession,
    String? classId,
    String? className,
    String? sectionId,
    String? sectionName,
    String? studentId,
    String? studentName,
    String? rollNumber,
    String? admissionNo,
    List<SubjectResultEntity>? subjectResults,
    double? grandTotalMarks,
    double? grandObtainedMarks,
    double? percentage,
    String? grade,
    bool? isPassed,
    int? classPosition,
    int? sectionPosition,
    int? overallRank,
    ResultStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    String? principalRemarks,
  }) {
    return ExamResultEntity(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      academicSession: academicSession ?? this.academicSession,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      admissionNo: admissionNo ?? this.admissionNo,
      subjectResults: subjectResults ?? this.subjectResults,
      grandTotalMarks: grandTotalMarks ?? this.grandTotalMarks,
      grandObtainedMarks: grandObtainedMarks ?? this.grandObtainedMarks,
      percentage: percentage ?? this.percentage,
      grade: grade ?? this.grade,
      isPassed: isPassed ?? this.isPassed,
      classPosition: classPosition ?? this.classPosition,
      sectionPosition: sectionPosition ?? this.sectionPosition,
      overallRank: overallRank ?? this.overallRank,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      principalRemarks: principalRemarks ?? this.principalRemarks,
    );
  }

  @override
  List<Object?> get props => [
        id,
        examId,
        examName,
        academicSession,
        classId,
        className,
        sectionId,
        sectionName,
        studentId,
        studentName,
        rollNumber,
        admissionNo,
        subjectResults,
        grandTotalMarks,
        grandObtainedMarks,
        percentage,
        grade,
        isPassed,
        classPosition,
        sectionPosition,
        overallRank,
        status,
        createdAt,
        updatedAt,
        publishedAt,
        principalRemarks,
      ];
}
