import 'dart:convert';

import 'package:equatable/equatable.dart';

enum ResultStatus {
  draft,
  generated,
  verified,
  approved,
  published,
  locked,

  /// Retained for backward compatibility with existing Firestore records.
  unpublished,
}

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
    this.generatedAt,
    this.generatedBy = '',
    this.verifiedAt,
    this.verifiedBy = '',
    this.approvedAt,
    this.approvedBy = '',
    this.publishedAt,
    this.publishedBy = '',
    this.lockedAt,
    this.lockedBy = '',
    this.unlockedAt,
    this.unlockedBy = '',
    this.unlockReason = '',
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

  final DateTime? generatedAt;
  final String generatedBy;

  final DateTime? verifiedAt;
  final String verifiedBy;

  final DateTime? approvedAt;
  final String approvedBy;

  final DateTime? publishedAt;
  final String publishedBy;

  final DateTime? lockedAt;
  final String lockedBy;

  final DateTime? unlockedAt;
  final String unlockedBy;
  final String unlockReason;

  final String principalRemarks;

  bool get isDraft => status == ResultStatus.draft;

  bool get isGenerated => status == ResultStatus.generated;

  bool get isVerified => status == ResultStatus.verified;

  bool get isApproved => status == ResultStatus.approved;

  bool get isPublished =>
      status == ResultStatus.published || status == ResultStatus.locked;

  bool get isLocked => status == ResultStatus.locked;

  bool get isVisibleToParent => isPublished;

  bool get canRegenerate =>
      status == ResultStatus.draft ||
      status == ResultStatus.generated ||
      status == ResultStatus.verified ||
      status == ResultStatus.unpublished;

  bool get canVerify => status == ResultStatus.generated;

  bool get canApprove => status == ResultStatus.verified;

  bool get canPublish => status == ResultStatus.approved;

  bool get canLock => status == ResultStatus.published;

  bool get canUnlock => status == ResultStatus.locked;

  static String documentIdFor({
    required String examId,
    required String classId,
    required String sectionId,
    required String studentId,
  }) {
    final identity = '$examId|$classId|$sectionId|$studentId';

    return base64Url
        .encode(utf8.encode(identity))
        .replaceAll('=', '');
  }

  static bool canTransition({
    required ResultStatus current,
    required ResultStatus next,
  }) {
    if (current == next) {
      return true;
    }

    return switch (current) {
      ResultStatus.draft =>
        next == ResultStatus.generated,
      ResultStatus.generated =>
        next == ResultStatus.verified ||
            next == ResultStatus.draft,
      ResultStatus.verified =>
        next == ResultStatus.approved ||
            next == ResultStatus.generated,
      ResultStatus.approved =>
        next == ResultStatus.published ||
            next == ResultStatus.verified,
      ResultStatus.published =>
        next == ResultStatus.locked ||
            next == ResultStatus.approved ||
            next == ResultStatus.unpublished,
      ResultStatus.locked =>
        next == ResultStatus.published,
      ResultStatus.unpublished =>
        next == ResultStatus.approved ||
            next == ResultStatus.published,
    };
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
    DateTime? generatedAt,
    String? generatedBy,
    DateTime? verifiedAt,
    String? verifiedBy,
    DateTime? approvedAt,
    String? approvedBy,
    DateTime? publishedAt,
    String? publishedBy,
    DateTime? lockedAt,
    String? lockedBy,
    DateTime? unlockedAt,
    String? unlockedBy,
    String? unlockReason,
    String? principalRemarks,
  }) {
    return ExamResultEntity(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      academicSession:
          academicSession ?? this.academicSession,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      admissionNo: admissionNo ?? this.admissionNo,
      subjectResults:
          subjectResults ?? this.subjectResults,
      grandTotalMarks:
          grandTotalMarks ?? this.grandTotalMarks,
      grandObtainedMarks:
          grandObtainedMarks ?? this.grandObtainedMarks,
      percentage: percentage ?? this.percentage,
      grade: grade ?? this.grade,
      isPassed: isPassed ?? this.isPassed,
      classPosition:
          classPosition ?? this.classPosition,
      sectionPosition:
          sectionPosition ?? this.sectionPosition,
      overallRank: overallRank ?? this.overallRank,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      generatedAt: generatedAt ?? this.generatedAt,
      generatedBy: generatedBy ?? this.generatedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      publishedAt: publishedAt ?? this.publishedAt,
      publishedBy: publishedBy ?? this.publishedBy,
      lockedAt: lockedAt ?? this.lockedAt,
      lockedBy: lockedBy ?? this.lockedBy,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      unlockedBy: unlockedBy ?? this.unlockedBy,
      unlockReason: unlockReason ?? this.unlockReason,
      principalRemarks:
          principalRemarks ?? this.principalRemarks,
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
        generatedAt,
        generatedBy,
        verifiedAt,
        verifiedBy,
        approvedAt,
        approvedBy,
        publishedAt,
        publishedBy,
        lockedAt,
        lockedBy,
        unlockedAt,
        unlockedBy,
        unlockReason,
        principalRemarks,
      ];
}