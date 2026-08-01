import 'package:equatable/equatable.dart';

enum NoticeStatus { draft, scheduled, published, expired, archived }

enum NoticeAudienceType {
  wholeSchool,
  students,
  parents,
  teachers,
  staff,
  selectedClasses,
  selectedSections,
}

enum NoticePriority { normal, important, urgent, emergency }

class NoticeAttachmentEntity extends Equatable {
  const NoticeAttachmentEntity({
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

class NoticeEntity extends Equatable {
  NoticeEntity({
    required this.id,
    required this.academicSession,
    required this.title,
    required this.message,
    required this.priority,
    required this.audienceType,
    required List<String> classIds,
    required List<String> sectionIds,
    required this.status,
    required this.publishAt,
    required this.expireAt,
    required this.acknowledgementRequired,
    required this.calendarEventId,
    required List<NoticeAttachmentEntity> attachments,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.publishedBy,
    this.publishedAt,
  }) : classIds = List<String>.unmodifiable(classIds),
       sectionIds = List<String>.unmodifiable(sectionIds),
       attachments = List<NoticeAttachmentEntity>.unmodifiable(attachments);

  final String id;
  final String academicSession;
  final String title;
  final String message;
  final NoticePriority priority;
  final NoticeAudienceType audienceType;
  final List<String> classIds;
  final List<String> sectionIds;
  final NoticeStatus status;
  final DateTime? publishAt;
  final DateTime? expireAt;
  final bool acknowledgementRequired;
  final String? calendarEventId;
  final List<NoticeAttachmentEntity> attachments;
  final String createdBy;
  final String updatedBy;
  final String? publishedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  bool get isExpired => expireAt != null && expireAt!.isBefore(DateTime.now());

  NoticeEntity copyWith({
    NoticeStatus? status,
    DateTime? publishAt,
    DateTime? expireAt,
    bool? acknowledgementRequired,
    String? updatedBy,
    String? publishedBy,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return NoticeEntity(
      id: id,
      academicSession: academicSession,
      title: title,
      message: message,
      priority: priority,
      audienceType: audienceType,
      classIds: classIds,
      sectionIds: sectionIds,
      status: status ?? this.status,
      publishAt: publishAt ?? this.publishAt,
      expireAt: expireAt ?? this.expireAt,
      acknowledgementRequired:
          acknowledgementRequired ?? this.acknowledgementRequired,
      calendarEventId: calendarEventId,
      attachments: attachments,
      createdBy: createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      publishedBy: publishedBy ?? this.publishedBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    academicSession,
    title,
    message,
    priority,
    audienceType,
    classIds,
    sectionIds,
    status,
    publishAt,
    expireAt,
    acknowledgementRequired,
    calendarEventId,
    attachments,
    updatedBy,
    publishedBy,
    updatedAt,
    publishedAt,
  ];
}
