import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/whatsapp_broadcast_entity.dart';

class WhatsAppBroadcastModel extends WhatsAppBroadcastEntity {
  const WhatsAppBroadcastModel({
    required super.id,
    required super.title,
    required super.templateName,
    required super.languageCode,
    required super.audience,
    required super.targetIds,
    required super.parameters,
    required super.automationType,
    required super.status,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.attachmentUrl,
    super.scheduledAt,
    super.completedAt,
    super.totalRecipients,
    super.successCount,
    super.failureCount,
    super.failureReason,
  });

  factory WhatsAppBroadcastModel.fromEntity(WhatsAppBroadcastEntity entity) {
    return WhatsAppBroadcastModel(
      id: entity.id,
      title: entity.title,
      templateName: entity.templateName,
      languageCode: entity.languageCode,
      audience: entity.audience,
      targetIds: entity.targetIds,
      parameters: entity.parameters,
      automationType: entity.automationType,
      status: entity.status,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      attachmentUrl: entity.attachmentUrl,
      scheduledAt: entity.scheduledAt,
      completedAt: entity.completedAt,
      totalRecipients: entity.totalRecipients,
      successCount: entity.successCount,
      failureCount: entity.failureCount,
      failureReason: entity.failureReason,
    );
  }

  factory WhatsAppBroadcastModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return WhatsAppBroadcastModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      templateName: map['templateName'] as String? ?? '',
      languageCode: map['languageCode'] as String? ?? 'en',
      audience: WhatsAppBroadcastAudience.values.firstWhere(
        (item) => item.name == map['audience'],
        orElse: () => WhatsAppBroadcastAudience.wholeSchool,
      ),
      targetIds: List<String>.from((map['targetIds'] as List?) ?? const []),
      parameters: Map<String, String>.from(
        (map['parameters'] as Map?) ?? const {},
      ),
      automationType: WhatsAppAutomationType.values.firstWhere(
        (item) => item.name == map['automationType'],
        orElse: () => WhatsAppAutomationType.manual,
      ),
      status: WhatsAppBroadcastStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => WhatsAppBroadcastStatus.draft,
      ),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
      attachmentUrl: map['attachmentUrl'] as String? ?? '',
      scheduledAt: map['scheduledAt'] == null ? null : date(map['scheduledAt']),
      completedAt: map['completedAt'] == null ? null : date(map['completedAt']),
      totalRecipients: (map['totalRecipients'] as num?)?.toInt() ?? 0,
      successCount: (map['successCount'] as num?)?.toInt() ?? 0,
      failureCount: (map['failureCount'] as num?)?.toInt() ?? 0,
      failureReason: map['failureReason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'templateName': templateName,
    'languageCode': languageCode,
    'audience': audience.name,
    'targetIds': targetIds,
    'parameters': parameters,
    'automationType': automationType.name,
    'status': status.name,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'attachmentUrl': attachmentUrl,
    'scheduledAt': scheduledAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'totalRecipients': totalRecipients,
    'successCount': successCount,
    'failureCount': failureCount,
    'failureReason': failureReason,
    'schemaVersion': 1,
  };
}
