import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/push_notification_request_entity.dart';

class PushNotificationRequestModel extends PushNotificationRequestEntity {
  const PushNotificationRequestModel({
    required super.id,
    required super.title,
    required super.body,
    required super.targetType,
    required super.targetValue,
    required super.data,
    required super.status,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.sentAt,
    super.failureReason,
  });

  factory PushNotificationRequestModel.fromEntity(
    PushNotificationRequestEntity entity,
  ) {
    return PushNotificationRequestModel(
      id: entity.id,
      title: entity.title,
      body: entity.body,
      targetType: entity.targetType,
      targetValue: entity.targetValue,
      data: entity.data,
      status: entity.status,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      sentAt: entity.sentAt,
      failureReason: entity.failureReason,
    );
  }

  factory PushNotificationRequestModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return PushNotificationRequestModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      targetType: PushTargetType.values.firstWhere(
        (item) => item.name == map['targetType'],
        orElse: () => PushTargetType.topic,
      ),
      targetValue: map['targetValue'] as String? ?? '',
      data: Map<String, String>.from((map['data'] as Map?) ?? const {}),
      status: PushRequestStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => PushRequestStatus.pending,
      ),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
      sentAt: map['sentAt'] == null ? null : date(map['sentAt']),
      failureReason: map['failureReason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'targetType': targetType.name,
    'targetValue': targetValue,
    'data': data,
    'status': status.name,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sentAt': sentAt?.toIso8601String(),
    'failureReason': failureReason,
    'schemaVersion': 1,
  };
}
