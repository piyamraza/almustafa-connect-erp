import 'package:equatable/equatable.dart';

enum WhatsAppMessageStatus { queued, sent, delivered, read, failed }

class WhatsAppMessageRequestEntity extends Equatable {
  const WhatsAppMessageRequestEntity({
    required this.id,
    required this.recipientPhone,
    required this.templateName,
    required this.languageCode,
    required this.parameters,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.attachmentUrl = '',
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.failureReason = '',
    this.providerMessageId = '',
    this.retryCount = 0,
  });

  final String id;
  final String recipientPhone;
  final String templateName;
  final String languageCode;
  final Map<String, String> parameters;
  final WhatsAppMessageStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String attachmentUrl;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String failureReason;
  final String providerMessageId;
  final int retryCount;

  @override
  List<Object?> get props => [
    id,
    recipientPhone,
    templateName,
    languageCode,
    parameters,
    status,
    createdBy,
    createdAt,
    updatedAt,
    attachmentUrl,
    sentAt,
    deliveredAt,
    readAt,
    failureReason,
    providerMessageId,
    retryCount,
  ];
}
