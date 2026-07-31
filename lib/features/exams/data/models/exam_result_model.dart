import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/exam_result_entity.dart';

class SubjectResultModel extends SubjectResultEntity {
  const SubjectResultModel({
    required super.subjectId,
    required super.subjectName,
    required super.totalMarks,
    required super.obtainedMarks,
    required super.isAbsent,
    required super.isPassed,
    required super.remarks,
  });

  factory SubjectResultModel.fromEntity(SubjectResultEntity value) {
    return SubjectResultModel(
      subjectId: value.subjectId,
      subjectName: value.subjectName,
      totalMarks: value.totalMarks,
      obtainedMarks: value.obtainedMarks,
      isAbsent: value.isAbsent,
      isPassed: value.isPassed,
      remarks: value.remarks,
    );
  }

  factory SubjectResultModel.fromMap(Map<String, dynamic> map) {
    return SubjectResultModel(
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      totalMarks: ExamResultModel._number(map['totalMarks']),
      obtainedMarks: ExamResultModel._number(map['obtainedMarks']),
      isAbsent: map['isAbsent'] as bool? ?? false,
      isPassed: map['isPassed'] as bool? ?? false,
      remarks: map['remarks'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'subjectId': subjectId,
        'subjectName': subjectName,
        'totalMarks': totalMarks,
        'obtainedMarks': obtainedMarks,
        'isAbsent': isAbsent,
        'isPassed': isPassed,
        'remarks': remarks,
      };
}

class ExamResultModel extends ExamResultEntity {
  const ExamResultModel({
    required super.id,
    required super.examId,
    required super.examName,
    required super.academicSession,
    required super.classId,
    required super.className,
    required super.sectionId,
    required super.sectionName,
    required super.studentId,
    required super.studentName,
    required super.rollNumber,
    required super.admissionNo,
    required super.subjectResults,
    required super.grandTotalMarks,
    required super.grandObtainedMarks,
    required super.percentage,
    required super.grade,
    required super.isPassed,
    required super.classPosition,
    required super.sectionPosition,
    required super.overallRank,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.publishedAt,
    super.principalRemarks = '',
  });

  factory ExamResultModel.fromEntity(ExamResultEntity value) {
    return ExamResultModel(
      id: value.id,
      examId: value.examId,
      examName: value.examName,
      academicSession: value.academicSession,
      classId: value.classId,
      className: value.className,
      sectionId: value.sectionId,
      sectionName: value.sectionName,
      studentId: value.studentId,
      studentName: value.studentName,
      rollNumber: value.rollNumber,
      admissionNo: value.admissionNo,
      subjectResults: value.subjectResults,
      grandTotalMarks: value.grandTotalMarks,
      grandObtainedMarks: value.grandObtainedMarks,
      percentage: value.percentage,
      grade: value.grade,
      isPassed: value.isPassed,
      classPosition: value.classPosition,
      sectionPosition: value.sectionPosition,
      overallRank: value.overallRank,
      status: value.status,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
      publishedAt: value.publishedAt,
      principalRemarks: value.principalRemarks,
    );
  }

  factory ExamResultModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    final rawSubjects = map['subjectResults'];
    final subjectResults = rawSubjects is List
        ? rawSubjects
            .whereType<Map>()
            .map(
              (value) => SubjectResultModel.fromMap(
                Map<String, dynamic>.from(value),
              ),
            )
            .toList(growable: false)
        : const <SubjectResultEntity>[];
    return ExamResultModel(
      id: map['id'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      examName: map['examName'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      sectionName: map['sectionName'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      rollNumber: map['rollNumber'] as String? ?? '',
      admissionNo: map['admissionNo'] as String? ?? '',
      subjectResults: subjectResults,
      grandTotalMarks: _number(map['grandTotalMarks']),
      grandObtainedMarks: _number(map['grandObtainedMarks']),
      percentage: _number(map['percentage']),
      grade: map['grade'] as String? ?? '-',
      isPassed: map['isPassed'] as bool? ?? false,
      classPosition: _integer(map['classPosition']),
      sectionPosition: _integer(map['sectionPosition']),
      overallRank: _integer(map['overallRank']),
      status: _status(map['status']),
      createdAt: _date(map['createdAt']) ?? now,
      updatedAt: _date(map['updatedAt']) ?? now,
      publishedAt: _date(map['publishedAt']),
      principalRemarks: map['principalRemarks'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'examId': examId,
        'examName': examName,
        'academicSession': academicSession,
        'classId': classId,
        'className': className,
        'sectionId': sectionId,
        'sectionName': sectionName,
        'studentId': studentId,
        'studentName': studentName,
        'rollNumber': rollNumber,
        'admissionNo': admissionNo,
        'subjectResults': subjectResults
            .map((value) => SubjectResultModel.fromEntity(value).toMap())
            .toList(growable: false),
        'grandTotalMarks': grandTotalMarks,
        'grandObtainedMarks': grandObtainedMarks,
        'percentage': percentage,
        'grade': grade,
        'isPassed': isPassed,
        'classPosition': classPosition,
        'sectionPosition': sectionPosition,
        'overallRank': overallRank,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'publishedAt': publishedAt?.toIso8601String(),
        'principalRemarks': principalRemarks,
      };

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static int _integer(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return value is String ? DateTime.tryParse(value) : null;
  }

  static ResultStatus _status(dynamic value) {
    final name = value?.toString();
    for (final status in ResultStatus.values) {
      if (status.name == name) return status;
    }
    return ResultStatus.draft;
  }
}
