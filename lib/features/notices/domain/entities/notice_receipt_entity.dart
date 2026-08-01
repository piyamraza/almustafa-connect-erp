import 'package:equatable/equatable.dart';

enum NoticeDeliveryStatus {
  pending,
  sent,
  delivered,
  read,
  acknowledged,
  failed,
}

class NoticeReceiptEntity extends Equatable {
  const NoticeReceiptEntity({
    required this.id,
    required this.noticeId,
    required this.recipientId,
    required this.recipientName,
    required this.recipientType,
    required this.status,
    required this.sentAt,
    required this.deliveredAt,
    required this.readAt,
    required this.acknowledgedAt,
    required this.failureReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String noticeId;
  final String recipientId;
  final String recipientName;
  final String recipientType;
  final NoticeDeliveryStatus status;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? acknowledgedAt;
  final String failureReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoticeReceiptEntity copyWith({
    NoticeDeliveryStatus? status,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    DateTime? acknowledgedAt,
    String? failureReason,
    DateTime? updatedAt,
  }) {
    return NoticeReceiptEntity(
      id: id,
      noticeId: noticeId,
      recipientId: recipientId,
      recipientName: recipientName,
      recipientType: recipientType,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    noticeId,
    recipientId,
    status,
    sentAt,
    deliveredAt,
    readAt,
    acknowledgedAt,
    failureReason,
    updatedAt,
  ];
}
