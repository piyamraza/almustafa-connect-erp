import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notice_entity.dart';

class NoticeModel extends NoticeEntity {
  NoticeModel({
    required super.id,
    required super.academicSession,
    required super.title,
    required super.message,
    required super.priority,
    required super.audienceType,
    required super.classIds,
    required super.sectionIds,
    required super.status,
    required super.publishAt,
    required super.expireAt,
    required super.acknowledgementRequired,
    required super.calendarEventId,
    required super.attachments,
    required super.createdBy,
    required super.updatedBy,
    required super.createdAt,
    required super.updatedAt,
    super.publishedBy,
    super.publishedAt,
  });

  factory NoticeModel.fromEntity(NoticeEntity value) => NoticeModel(
    id: value.id,
    academicSession: value.academicSession,
    title: value.title,
    message: value.message,
    priority: value.priority,
    audienceType: value.audienceType,
    classIds: value.classIds,
    sectionIds: value.sectionIds,
    status: value.status,
    publishAt: value.publishAt,
    expireAt: value.expireAt,
    acknowledgementRequired: value.acknowledgementRequired,
    calendarEventId: value.calendarEventId,
    attachments: value.attachments,
    createdBy: value.createdBy,
    updatedBy: value.updatedBy,
    createdAt: value.createdAt,
    updatedAt: value.updatedAt,
    publishedBy: value.publishedBy,
    publishedAt: value.publishedAt,
  );

  factory NoticeModel.fromMap(Map<String, dynamic> map) {
    final rawAttachments =
        map['attachments'] as List<dynamic>? ?? const <dynamic>[];

    return NoticeModel(
      id: map['id'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      priority: NoticePriority.values.firstWhere(
        (item) => item.name == map['priority'],
        orElse: () => NoticePriority.normal,
      ),
      audienceType: NoticeAudienceType.values.firstWhere(
        (item) => item.name == map['audienceType'],
        orElse: () => NoticeAudienceType.wholeSchool,
      ),
      classIds: (map['classIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      sectionIds: (map['sectionIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      status: NoticeStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => NoticeStatus.draft,
      ),
      publishAt: _nullableDate(map['publishAt']),
      expireAt: _nullableDate(map['expireAt']),
      acknowledgementRequired: map['acknowledgementRequired'] as bool? ?? false,
      calendarEventId: map['calendarEventId'] as String?,
      attachments: rawAttachments
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => NoticeAttachmentEntity(
              id: item['id'] as String? ?? '',
              fileName: item['fileName'] as String? ?? '',
              fileUrl: item['fileUrl'] as String? ?? '',
              fileType: item['fileType'] as String? ?? '',
              fileSize: (item['fileSize'] as num?)?.toInt() ?? 0,
              storagePath: item['storagePath'] as String? ?? '',
            ),
          )
          .toList(growable: false),
      createdBy: map['createdBy'] as String? ?? 'Admin',
      updatedBy: map['updatedBy'] as String? ?? 'Admin',
      publishedBy: map['publishedBy'] as String?,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
      publishedAt: _nullableDate(map['publishedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'academicSession': academicSession,
    'title': title,
    'message': message,
    'priority': priority.name,
    'audienceType': audienceType.name,
    'classIds': classIds,
    'sectionIds': sectionIds,
    'status': status.name,
    'publishAt': publishAt == null ? null : Timestamp.fromDate(publishAt!),
    'expireAt': expireAt == null ? null : Timestamp.fromDate(expireAt!),
    'acknowledgementRequired': acknowledgementRequired,
    'calendarEventId': calendarEventId,
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
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'publishedBy': publishedBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'publishedAt': publishedAt == null
        ? null
        : Timestamp.fromDate(publishedAt!),
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDate(dynamic value) =>
      value == null ? null : _date(value);
}
