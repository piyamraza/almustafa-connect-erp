import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/parent_notification_entity.dart';

class ParentNotificationModel extends ParentNotificationEntity {
  const ParentNotificationModel({
    required super.id,
    required super.parentId,
    required super.studentId,
    required super.title,
    required super.message,
    required super.type,
    required super.isRead,
    required super.createdAt,
    required super.readAt,
    required super.referenceId,
    required super.actionRoute,
  });

  factory ParentNotificationModel.fromEntity(ParentNotificationEntity value) {
    return ParentNotificationModel(
      id: value.id,
      parentId: value.parentId,
      studentId: value.studentId,
      title: value.title,
      message: value.message,
      type: value.type,
      isRead: value.isRead,
      createdAt: value.createdAt,
      readAt: value.readAt,
      referenceId: value.referenceId,
      actionRoute: value.actionRoute,
    );
  }

  factory ParentNotificationModel.fromMap(Map<String, dynamic> map) {
    return ParentNotificationModel(
      id: map['id'] as String? ?? '',
      parentId: map['parentId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: ParentNotificationType.values.firstWhere(
        (item) => item.name == map['type'],
        orElse: () => ParentNotificationType.general,
      ),
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _date(map['createdAt']),
      readAt: _nullableDate(map['readAt']),
      referenceId: map['referenceId'] as String? ?? '',
      actionRoute: map['actionRoute'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'parentId': parentId,
    'studentId': studentId,
    'title': title,
    'message': message,
    'type': type.name,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
    'readAt': readAt == null ? null : Timestamp.fromDate(readAt!),
    'referenceId': referenceId,
    'actionRoute': actionRoute,
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDate(dynamic value) =>
      value == null ? null : _date(value);
}
