import 'package:equatable/equatable.dart';

enum CommunicationChannel { inApp, pushNotification, whatsapp }

enum CommunicationAudienceType {
  wholeSchool,
  teachers,
  parents,
  students,
  staff,
  classSection,
  selectedUsers,
}

enum CommunicationMessageStatus { draft, scheduled, published, archived }

class CommunicationMessageEntity extends Equatable {
  const CommunicationMessageEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.channels,
    required this.audienceType,
    required this.targetIds,
    required this.status,
    required this.isPinned,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledAt,
    this.publishedAt,
    this.expiresAt,
    this.attachmentUrl = '',
  });

  final String id;
  final String title;
  final String body;
  final List<CommunicationChannel> channels;
  final CommunicationAudienceType audienceType;
  final List<String> targetIds;
  final CommunicationMessageStatus status;
  final bool isPinned;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final String attachmentUrl;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    channels,
    audienceType,
    targetIds,
    status,
    isPinned,
    createdBy,
    createdAt,
    updatedAt,
    scheduledAt,
    publishedAt,
    expiresAt,
    attachmentUrl,
  ];
}
