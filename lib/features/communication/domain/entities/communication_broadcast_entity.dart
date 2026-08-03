import 'package:equatable/equatable.dart';

import 'communication_message_entity.dart';

enum CommunicationBroadcastStatus {
  draft,
  scheduled,
  queued,
  processing,
  sent,
  partiallyFailed,
  failed,
  cancelled,
}

class CommunicationBroadcastEntity extends Equatable {
  const CommunicationBroadcastEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.channels,
    required this.audienceType,
    required this.targetIds,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledAt,
    this.sentAt,
    this.attachmentUrl = '',
    this.totalRecipients = 0,
    this.sentCount = 0,
    this.deliveredCount = 0,
    this.readCount = 0,
    this.failedCount = 0,
    this.failureReason = '',
    this.deduplicationKey = '',
  });

  final String id;
  final String title;
  final String body;
  final List<CommunicationChannel> channels;
  final CommunicationAudienceType audienceType;
  final List<String> targetIds;
  final CommunicationBroadcastStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final String attachmentUrl;
  final int totalRecipients;
  final int sentCount;
  final int deliveredCount;
  final int readCount;
  final int failedCount;
  final String failureReason;
  final String deduplicationKey;

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    channels,
    audienceType,
    targetIds,
    status,
    createdBy,
    createdAt,
    updatedAt,
    scheduledAt,
    sentAt,
    attachmentUrl,
    totalRecipients,
    sentCount,
    deliveredCount,
    readCount,
    failedCount,
    failureReason,
    deduplicationKey,
  ];
}
