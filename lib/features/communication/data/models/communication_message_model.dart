import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/communication_message_entity.dart';

class CommunicationMessageModel extends CommunicationMessageEntity {
  const CommunicationMessageModel({
    required super.id,
    required super.title,
    required super.body,
    required super.channels,
    required super.audienceType,
    required super.targetIds,
    required super.status,
    required super.isPinned,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.scheduledAt,
    super.publishedAt,
    super.expiresAt,
    super.attachmentUrl,
  });

  factory CommunicationMessageModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    DateTime? nullableDate(dynamic value) => value == null ? null : date(value);

    return CommunicationMessageModel(
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
      status: CommunicationMessageStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => CommunicationMessageStatus.draft,
      ),
      isPinned: map['isPinned'] as bool? ?? false,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
      scheduledAt: nullableDate(map['scheduledAt']),
      publishedAt: nullableDate(map['publishedAt']),
      expiresAt: nullableDate(map['expiresAt']),
      attachmentUrl: map['attachmentUrl'] as String? ?? '',
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
    'isPinned': isPinned,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'scheduledAt': scheduledAt?.toIso8601String(),
    'publishedAt': publishedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'attachmentUrl': attachmentUrl,
    'schemaVersion': 1,
  };
}
