import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/communication_broadcast_entity.dart';
import '../../domain/entities/communication_message_entity.dart';

class CommunicationBroadcastModel extends CommunicationBroadcastEntity {
  const CommunicationBroadcastModel({
    required super.id,
    required super.title,
    required super.body,
    required super.channels,
    required super.audienceType,
    required super.targetIds,
    required super.status,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.scheduledAt,
    super.sentAt,
    super.attachmentUrl,
    super.totalRecipients,
    super.sentCount,
    super.deliveredCount,
    super.readCount,
    super.failedCount,
    super.failureReason,
    super.deduplicationKey,
  });

  factory CommunicationBroadcastModel.fromEntity(
    CommunicationBroadcastEntity entity,
  ) {
    return CommunicationBroadcastModel(
      id: entity.id,
      title: entity.title,
      body: entity.body,
      channels: entity.channels,
      audienceType: entity.audienceType,
      targetIds: entity.targetIds,
      status: entity.status,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      scheduledAt: entity.scheduledAt,
      sentAt: entity.sentAt,
      attachmentUrl: entity.attachmentUrl,
      totalRecipients: entity.totalRecipients,
      sentCount: entity.sentCount,
      deliveredCount: entity.deliveredCount,
      readCount: entity.readCount,
      failedCount: entity.failedCount,
      failureReason: entity.failureReason,
      deduplicationKey: entity.deduplicationKey,
    );
  }

  factory CommunicationBroadcastModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return CommunicationBroadcastModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      channels: ((map['channels'] as List?) ?? const [])
          .map(
            (value) => CommunicationChannel.values.firstWhere(
              (item) => item.name == value,
              orElse: () => CommunicationChannel.inApp,
            ),
          )
          .toList(),
      audienceType: CommunicationAudienceType.values.firstWhere(
        (item) => item.name == map['audienceType'],
        orElse: () => CommunicationAudienceType.wholeSchool,
      ),
      targetIds: List<String>.from((map['targetIds'] as List?) ?? const []),
      status: CommunicationBroadcastStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => CommunicationBroadcastStatus.draft,
      ),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
      scheduledAt: map['scheduledAt'] == null ? null : date(map['scheduledAt']),
      sentAt: map['sentAt'] == null ? null : date(map['sentAt']),
      attachmentUrl: map['attachmentUrl'] as String? ?? '',
      totalRecipients: (map['totalRecipients'] as num?)?.toInt() ?? 0,
      sentCount: (map['sentCount'] as num?)?.toInt() ?? 0,
      deliveredCount: (map['deliveredCount'] as num?)?.toInt() ?? 0,
      readCount: (map['readCount'] as num?)?.toInt() ?? 0,
      failedCount: (map['failedCount'] as num?)?.toInt() ?? 0,
      failureReason: map['failureReason'] as String? ?? '',
      deduplicationKey: map['deduplicationKey'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'channels': channels.map((item) => item.name).toList(),
    'audienceType': audienceType.name,
    'targetIds': targetIds,
    'status': status.name,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'scheduledAt': scheduledAt?.toIso8601String(),
    'sentAt': sentAt?.toIso8601String(),
    'attachmentUrl': attachmentUrl,
    'totalRecipients': totalRecipients,
    'sentCount': sentCount,
    'deliveredCount': deliveredCount,
    'readCount': readCount,
    'failedCount': failedCount,
    'failureReason': failureReason,
    'deduplicationKey': deduplicationKey,
    'schemaVersion': 1,
  };
}
