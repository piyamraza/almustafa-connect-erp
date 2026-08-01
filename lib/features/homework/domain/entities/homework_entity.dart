import 'package:equatable/equatable.dart';

enum HomeworkStatus { draft, published, archived }

class HomeworkAttachmentEntity extends Equatable {
  const HomeworkAttachmentEntity({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.storagePath,
  });

  final String id;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String storagePath;

  @override
  List<Object> get props => [
    id,
    fileName,
    fileUrl,
    fileType,
    fileSize,
    storagePath,
  ];
}

class HomeworkEntity extends Equatable {
  HomeworkEntity({
    required this.id,
    required this.academicSession,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.title,
    required this.description,
    required this.instructions,
    required this.assignedDate,
    required this.dueDate,
    required this.status,
    required List<HomeworkAttachmentEntity> attachments,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.publishedBy,
    this.publishedAt,
    this.sourceHomeworkId,
  }) : attachments = List<HomeworkAttachmentEntity>.unmodifiable(attachments);

  final String id;
  final String academicSession;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final String title;
  final String description;
  final String instructions;
  final DateTime assignedDate;
  final DateTime dueDate;
  final HomeworkStatus status;
  final List<HomeworkAttachmentEntity> attachments;
  final String createdBy;
  final String updatedBy;
  final String? publishedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final String? sourceHomeworkId;

  bool get isOverdue =>
      status == HomeworkStatus.published && dueDate.isBefore(DateTime.now());

  HomeworkEntity copyWith({
    String? id,
    DateTime? assignedDate,
    DateTime? dueDate,
    HomeworkStatus? status,
    List<HomeworkAttachmentEntity>? attachments,
    String? updatedBy,
    String? publishedBy,
    DateTime? updatedAt,
    DateTime? publishedAt,
    String? sourceHomeworkId,
  }) {
    return HomeworkEntity(
      id: id ?? this.id,
      academicSession: academicSession,
      classId: classId,
      className: className,
      sectionId: sectionId,
      sectionName: sectionName,
      subjectId: subjectId,
      subjectName: subjectName,
      teacherId: teacherId,
      teacherName: teacherName,
      title: title,
      description: description,
      instructions: instructions,
      assignedDate: assignedDate ?? this.assignedDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      createdBy: createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      publishedBy: publishedBy ?? this.publishedBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      sourceHomeworkId: sourceHomeworkId ?? this.sourceHomeworkId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    academicSession,
    classId,
    sectionId,
    subjectId,
    teacherId,
    title,
    assignedDate,
    dueDate,
    status,
    attachments,
    updatedBy,
    publishedBy,
    updatedAt,
    publishedAt,
    sourceHomeworkId,
  ];
}
