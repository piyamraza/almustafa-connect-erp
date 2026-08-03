import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/whatsapp_message_request_entity.dart';

class WhatsAppMessageRequestModel extends WhatsAppMessageRequestEntity {
  const WhatsAppMessageRequestModel({
    required super.id,
    required super.recipientPhone,
    required super.templateName,
    required super.languageCode,
    required super.parameters,
    required super.status,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.attachmentUrl,
    super.sentAt,
    super.deliveredAt,
    super.readAt,
    super.failureReason,
    super.providerMessageId,
    super.retryCount,
  });

  factory WhatsAppMessageRequestModel.fromEntity(
    WhatsAppMessageRequestEntity entity,
  ) {
    return WhatsAppMessageRequestModel(
      id: entity.id,
      recipientPhone: entity.recipientPhone,
      templateName: entity.templateName,
      languageCode: entity.languageCode,
      parameters: entity.parameters,
      status: entity.status,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      attachmentUrl: entity.attachmentUrl,
      sentAt: entity.sentAt,
      deliveredAt: entity.deliveredAt,
      readAt: entity.readAt,
      failureReason: entity.failureReason,
      providerMessageId: entity.providerMessageId,
      retryCount: entity.retryCount,
    );
  }

  factory WhatsAppMessageRequestModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return WhatsAppMessageRequestModel(
      id: map['id'] as String? ?? '',
      recipientPhone: map['recipientPhone'] as String? ?? '',
      templateName: map['templateName'] as String? ?? '',
      languageCode: map['languageCode'] as String? ?? 'en',
      parameters: Map<String, String>.from(
        (map['parameters'] as Map?) ?? const {},
      ),
      status: WhatsAppMessageStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => WhatsAppMessageStatus.queued,
      ),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
      attachmentUrl: map['attachmentUrl'] as String? ?? '',
      sentAt: map['sentAt'] == null ? null : date(map['sentAt']),
      deliveredAt: map['deliveredAt'] == null ? null : date(map['deliveredAt']),
      readAt: map['readAt'] == null ? null : date(map['readAt']),
      failureReason: map['failureReason'] as String? ?? '',
      providerMessageId: map['providerMessageId'] as String? ?? '',
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'recipientPhone': recipientPhone,
    'templateName': templateName,
    'languageCode': languageCode,
    'parameters': parameters,
    'status': status.name,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'attachmentUrl': attachmentUrl,
    'sentAt': sentAt?.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(),
    'readAt': readAt?.toIso8601String(),
    'failureReason': failureReason,
    'providerMessageId': providerMessageId,
    'retryCount': retryCount,
    'schemaVersion': 1,
  };
}
