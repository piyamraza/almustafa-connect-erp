import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/push_delivery_log_entity.dart';

class PushDeliveryLogModel extends PushDeliveryLogEntity {
  const PushDeliveryLogModel({
    required super.id,
    required super.requestId,
    required super.recipientId,
    required super.target,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.sentAt,
    super.deliveredAt,
    super.readAt,
    super.failureReason,
    super.retryCount,
  });

  factory PushDeliveryLogModel.fromEntity(PushDeliveryLogEntity entity) {
    return PushDeliveryLogModel(
      id: entity.id,
      requestId: entity.requestId,
      recipientId: entity.recipientId,
      target: entity.target,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      sentAt: entity.sentAt,
      deliveredAt: entity.deliveredAt,
      readAt: entity.readAt,
      failureReason: entity.failureReason,
      retryCount: entity.retryCount,
    );
  }

  factory PushDeliveryLogModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return PushDeliveryLogModel(
      id: map['id'] as String? ?? '',
      requestId: map['requestId'] as String? ?? '',
      recipientId: map['recipientId'] as String? ?? '',
      target: map['target'] as String? ?? '',
      status: PushDeliveryStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => PushDeliveryStatus.queued,
      ),
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
      sentAt: map['sentAt'] == null ? null : date(map['sentAt']),
      deliveredAt: map['deliveredAt'] == null ? null : date(map['deliveredAt']),
      readAt: map['readAt'] == null ? null : date(map['readAt']),
      failureReason: map['failureReason'] as String? ?? '',
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'requestId': requestId,
    'recipientId': recipientId,
    'target': target,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sentAt': sentAt?.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(),
    'readAt': readAt?.toIso8601String(),
    'failureReason': failureReason,
    'retryCount': retryCount,
    'schemaVersion': 1,
  };
}
