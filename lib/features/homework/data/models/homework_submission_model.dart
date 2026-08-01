import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/homework_entity.dart';
import '../../domain/entities/homework_submission_entity.dart';

class HomeworkSubmissionModel extends HomeworkSubmissionEntity {
  HomeworkSubmissionModel({
    required super.id,
    required super.homeworkId,
    required super.studentId,
    required super.studentName,
    required super.admissionNo,
    required super.classId,
    required super.sectionId,
    required super.submissionText,
    required super.attachments,
    required super.status,
    required super.submittedAt,
    required super.isLate,
    required super.teacherRemarks,
    required super.marksAwarded,
    required super.maxMarks,
    required super.reviewedBy,
    required super.reviewedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory HomeworkSubmissionModel.fromEntity(HomeworkSubmissionEntity value) {
    return HomeworkSubmissionModel(
      id: value.id,
      homeworkId: value.homeworkId,
      studentId: value.studentId,
      studentName: value.studentName,
      admissionNo: value.admissionNo,
      classId: value.classId,
      sectionId: value.sectionId,
      submissionText: value.submissionText,
      attachments: value.attachments,
      status: value.status,
      submittedAt: value.submittedAt,
      isLate: value.isLate,
      teacherRemarks: value.teacherRemarks,
      marksAwarded: value.marksAwarded,
      maxMarks: value.maxMarks,
      reviewedBy: value.reviewedBy,
      reviewedAt: value.reviewedAt,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

  factory HomeworkSubmissionModel.fromMap(Map<String, dynamic> map) {
    final raw = map['attachments'] as List<dynamic>? ?? const [];

    return HomeworkSubmissionModel(
      id: map['id'] as String? ?? '',
      homeworkId: map['homeworkId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      admissionNo: map['admissionNo'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      submissionText: map['submissionText'] as String? ?? '',
      attachments: raw
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => HomeworkAttachmentEntity(
              id: item['id'] as String? ?? '',
              fileName: item['fileName'] as String? ?? '',
              fileUrl: item['fileUrl'] as String? ?? '',
              fileType: item['fileType'] as String? ?? '',
              fileSize: (item['fileSize'] as num?)?.toInt() ?? 0,
              storagePath: item['storagePath'] as String? ?? '',
            ),
          )
          .toList(growable: false),
      status: HomeworkSubmissionStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => HomeworkSubmissionStatus.pending,
      ),
      submittedAt: _nullableDate(map['submittedAt']),
      isLate: map['isLate'] as bool? ?? false,
      teacherRemarks: map['teacherRemarks'] as String? ?? '',
      marksAwarded: (map['marksAwarded'] as num?)?.toDouble(),
      maxMarks: (map['maxMarks'] as num?)?.toDouble(),
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: _nullableDate(map['reviewedAt']),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'homeworkId': homeworkId,
    'studentId': studentId,
    'studentName': studentName,
    'admissionNo': admissionNo,
    'classId': classId,
    'sectionId': sectionId,
    'submissionText': submissionText,
    'attachments': attachments
        .map(
          (item) => {
            'id': item.id,
            'fileName': item.fileName,
            'fileUrl': item.fileUrl,
            'fileType': item.fileType,
            'fileSize': item.fileSize,
            'storagePath': item.storagePath,
          },
        )
        .toList(growable: false),
    'status': status.name,
    'submittedAt': submittedAt == null
        ? null
        : Timestamp.fromDate(submittedAt!),
    'isLate': isLate,
    'teacherRemarks': teacherRemarks,
    'marksAwarded': marksAwarded,
    'maxMarks': maxMarks,
    'reviewedBy': reviewedBy,
    'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDate(dynamic value) =>
      value == null ? null : _date(value);
}
