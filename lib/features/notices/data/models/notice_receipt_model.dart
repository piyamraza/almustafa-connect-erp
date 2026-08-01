import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notice_receipt_entity.dart';

class NoticeReceiptModel extends NoticeReceiptEntity {
  const NoticeReceiptModel({
    required super.id,
    required super.noticeId,
    required super.recipientId,
    required super.recipientName,
    required super.recipientType,
    required super.status,
    required super.sentAt,
    required super.deliveredAt,
    required super.readAt,
    required super.acknowledgedAt,
    required super.failureReason,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NoticeReceiptModel.fromEntity(NoticeReceiptEntity value) {
    return NoticeReceiptModel(
      id: value.id,
      noticeId: value.noticeId,
      recipientId: value.recipientId,
      recipientName: value.recipientName,
      recipientType: value.recipientType,
      status: value.status,
      sentAt: value.sentAt,
      deliveredAt: value.deliveredAt,
      readAt: value.readAt,
      acknowledgedAt: value.acknowledgedAt,
      failureReason: value.failureReason,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

  factory NoticeReceiptModel.fromMap(Map<String, dynamic> map) {
    return NoticeReceiptModel(
      id: map['id'] as String? ?? '',
      noticeId: map['noticeId'] as String? ?? '',
      recipientId: map['recipientId'] as String? ?? '',
      recipientName: map['recipientName'] as String? ?? '',
      recipientType: map['recipientType'] as String? ?? '',
      status: NoticeDeliveryStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => NoticeDeliveryStatus.pending,
      ),
      sentAt: _nullableDate(map['sentAt']),
      deliveredAt: _nullableDate(map['deliveredAt']),
      readAt: _nullableDate(map['readAt']),
      acknowledgedAt: _nullableDate(map['acknowledgedAt']),
      failureReason: map['failureReason'] as String? ?? '',
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'noticeId': noticeId,
    'recipientId': recipientId,
    'recipientName': recipientName,
    'recipientType': recipientType,
    'status': status.name,
    'sentAt': sentAt == null ? null : Timestamp.fromDate(sentAt!),
    'deliveredAt': deliveredAt == null
        ? null
        : Timestamp.fromDate(deliveredAt!),
    'readAt': readAt == null ? null : Timestamp.fromDate(readAt!),
    'acknowledgedAt': acknowledgedAt == null
        ? null
        : Timestamp.fromDate(acknowledgedAt!),
    'failureReason': failureReason,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDate(dynamic value) =>
      value == null ? null : _date(value);
}
