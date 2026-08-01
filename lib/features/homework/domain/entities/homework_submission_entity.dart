import 'package:equatable/equatable.dart';

import 'homework_entity.dart';

enum HomeworkSubmissionStatus { pending, submitted, late, returned, reviewed }

class HomeworkSubmissionEntity extends Equatable {
  HomeworkSubmissionEntity({
    required this.id,
    required this.homeworkId,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.classId,
    required this.sectionId,
    required this.submissionText,
    required List<HomeworkAttachmentEntity> attachments,
    required this.status,
    required this.submittedAt,
    required this.isLate,
    required this.teacherRemarks,
    required this.marksAwarded,
    required this.maxMarks,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  }) : attachments = List<HomeworkAttachmentEntity>.unmodifiable(attachments);

  final String id;
  final String homeworkId;
  final String studentId;
  final String studentName;
  final String admissionNo;
  final String classId;
  final String sectionId;
  final String submissionText;
  final List<HomeworkAttachmentEntity> attachments;
  final HomeworkSubmissionStatus status;
  final DateTime? submittedAt;
  final bool isLate;
  final String teacherRemarks;
  final double? marksAwarded;
  final double? maxMarks;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  HomeworkSubmissionEntity copyWith({
    String? submissionText,
    List<HomeworkAttachmentEntity>? attachments,
    HomeworkSubmissionStatus? status,
    DateTime? submittedAt,
    bool? isLate,
    String? teacherRemarks,
    double? marksAwarded,
    double? maxMarks,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? updatedAt,
  }) {
    return HomeworkSubmissionEntity(
      id: id,
      homeworkId: homeworkId,
      studentId: studentId,
      studentName: studentName,
      admissionNo: admissionNo,
      classId: classId,
      sectionId: sectionId,
      submissionText: submissionText ?? this.submissionText,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      isLate: isLate ?? this.isLate,
      teacherRemarks: teacherRemarks ?? this.teacherRemarks,
      marksAwarded: marksAwarded ?? this.marksAwarded,
      maxMarks: maxMarks ?? this.maxMarks,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    homeworkId,
    studentId,
    submissionText,
    attachments,
    status,
    submittedAt,
    isLate,
    teacherRemarks,
    marksAwarded,
    maxMarks,
    reviewedBy,
    reviewedAt,
    updatedAt,
  ];
}
