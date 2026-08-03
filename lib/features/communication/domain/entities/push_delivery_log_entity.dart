import 'package:equatable/equatable.dart';

enum PushDeliveryStatus { queued, sent, delivered, read, failed }

class PushDeliveryLogEntity extends Equatable {
  const PushDeliveryLogEntity({
    required this.id,
    required this.requestId,
    required this.recipientId,
    required this.target,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.failureReason = '',
    this.retryCount = 0,
  });

  final String id;
  final String requestId;
  final String recipientId;
  final String target;
  final PushDeliveryStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String failureReason;
  final int retryCount;

  @override
  List<Object?> get props => [
    id,
    requestId,
    recipientId,
    target,
    status,
    createdAt,
    updatedAt,
    sentAt,
    deliveredAt,
    readAt,
    failureReason,
    retryCount,
  ];
}
