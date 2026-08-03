import 'package:equatable/equatable.dart';

enum PushTargetType { topic, token, user }

enum PushRequestStatus { pending, sent, failed }

class PushNotificationRequestEntity extends Equatable {
  const PushNotificationRequestEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.targetType,
    required this.targetValue,
    required this.data,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
    this.failureReason = '',
  });

  final String id;
  final String title;
  final String body;
  final PushTargetType targetType;
  final String targetValue;
  final Map<String, String> data;
  final PushRequestStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;
  final String failureReason;

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    targetType,
    targetValue,
    data,
    status,
    createdBy,
    createdAt,
    updatedAt,
    sentAt,
    failureReason,
  ];
}
