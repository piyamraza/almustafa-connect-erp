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

  factory SubjectResultModel.fromEntity(
    SubjectResultEntity value,
  ) {
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

  factory SubjectResultModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return SubjectResultModel(
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      totalMarks:
          ExamResultModel.number(map['totalMarks']),
      obtainedMarks:
          ExamResultModel.number(map['obtainedMarks']),
      isAbsent: map['isAbsent'] as bool? ?? false,
      isPassed: map['isPassed'] as bool? ?? false,
      remarks: map['remarks'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'totalMarks': totalMarks,
      'obtainedMarks': obtainedMarks,
      'isAbsent': isAbsent,
      'isPassed': isPassed,
      'remarks': remarks,
    };
  }
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
    super.generatedAt,
    super.generatedBy,
    super.verifiedAt,
    super.verifiedBy,
    super.approvedAt,
    super.approvedBy,
    super.publishedAt,
    super.publishedBy,
    super.lockedAt,
    super.lockedBy,
    super.unlockedAt,
    super.unlockedBy,
    super.unlockReason,
    super.principalRemarks,
  });

  factory ExamResultModel.fromEntity(
    ExamResultEntity value,
  ) {
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
      generatedAt: value.generatedAt,
      generatedBy: value.generatedBy,
      verifiedAt: value.verifiedAt,
      verifiedBy: value.verifiedBy,
      approvedAt: value.approvedAt,
      approvedBy: value.approvedBy,
      publishedAt: value.publishedAt,
      publishedBy: value.publishedBy,
      lockedAt: value.lockedAt,
      lockedBy: value.lockedBy,
      unlockedAt: value.unlockedAt,
      unlockedBy: value.unlockedBy,
      unlockReason: value.unlockReason,
      principalRemarks: value.principalRemarks,
    );
  }

  factory ExamResultModel.fromMap(
    Map<String, dynamic> map,
  ) {
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

    final status = statusFromValue(map['status']);
    final createdAt = date(map['createdAt']) ?? now;
    final updatedAt = date(map['updatedAt']) ?? createdAt;
    final publishedAt = date(map['publishedAt']);

    return ExamResultModel(
      id: map['id'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      examName: map['examName'] as String? ?? '',
      academicSession:
          map['academicSession'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      sectionName:
          map['sectionName'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName:
          map['studentName'] as String? ?? '',
      rollNumber:
          map['rollNumber'] as String? ?? '',
      admissionNo:
          map['admissionNo'] as String? ?? '',
      subjectResults: subjectResults,
      grandTotalMarks:
          number(map['grandTotalMarks']),
      grandObtainedMarks:
          number(map['grandObtainedMarks']),
      percentage: number(map['percentage']),
      grade: map['grade'] as String? ?? '-',
      isPassed: map['isPassed'] as bool? ?? false,
      classPosition:
          integer(map['classPosition']),
      sectionPosition:
          integer(map['sectionPosition']),
      overallRank: integer(map['overallRank']),
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      generatedAt:
          date(map['generatedAt']) ??
              _legacyGeneratedAt(
                status: status,
                createdAt: createdAt,
              ),
      generatedBy:
          map['generatedBy'] as String? ?? '',
      verifiedAt: date(map['verifiedAt']),
      verifiedBy:
          map['verifiedBy'] as String? ?? '',
      approvedAt: date(map['approvedAt']),
      approvedBy:
          map['approvedBy'] as String? ?? '',
      publishedAt: publishedAt,
      publishedBy:
          map['publishedBy'] as String? ?? '',
      lockedAt: date(map['lockedAt']),
      lockedBy:
          map['lockedBy'] as String? ?? '',
      unlockedAt: date(map['unlockedAt']),
      unlockedBy:
          map['unlockedBy'] as String? ?? '',
      unlockReason:
          map['unlockReason'] as String? ?? '',
      principalRemarks:
          map['principalRemarks'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
          .map(
            (value) =>
                SubjectResultModel.fromEntity(value).toMap(),
          )
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
      'generatedAt':
          generatedAt?.toIso8601String(),
      'generatedBy': generatedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'publishedAt':
          publishedAt?.toIso8601String(),
      'publishedBy': publishedBy,
      'lockedAt': lockedAt?.toIso8601String(),
      'lockedBy': lockedBy,
      'unlockedAt':
          unlockedAt?.toIso8601String(),
      'unlockedBy': unlockedBy,
      'unlockReason': unlockReason,
      'principalRemarks': principalRemarks,
      'schemaVersion': 2,
    };
  }

  static double number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse('$value') ?? 0;
  }

  static int integer(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value') ?? 0;
  }

  static DateTime? date(dynamic value) {
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

  static ResultStatus statusFromValue(dynamic value) {
    final name = value?.toString().trim();

    for (final status in ResultStatus.values) {
      if (status.name == name) {
        return status;
      }
    }

    return ResultStatus.draft;
  }

  static DateTime? _legacyGeneratedAt({
    required ResultStatus status,
    required DateTime createdAt,
  }) {
    if (status == ResultStatus.draft) {
      return null;
    }

    return createdAt;
  }
}