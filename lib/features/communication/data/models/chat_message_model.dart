import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.threadId,
    required super.senderId,
    required super.senderName,
    required super.type,
    required super.text,
    required super.createdAt,
    required super.readBy,
    super.attachmentUrl,
    super.attachmentName,
    super.replyToMessageId,
    super.isDeleted,
  });

  factory ChatMessageModel.fromEntity(ChatMessageEntity entity) {
    return ChatMessageModel(
      id: entity.id,
      threadId: entity.threadId,
      senderId: entity.senderId,
      senderName: entity.senderName,
      type: entity.type,
      text: entity.text,
      createdAt: entity.createdAt,
      readBy: entity.readBy,
      attachmentUrl: entity.attachmentUrl,
      attachmentName: entity.attachmentName,
      replyToMessageId: entity.replyToMessageId,
      isDeleted: entity.isDeleted,
    );
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return ChatMessageModel(
      id: map['id'] as String? ?? '',
      threadId: map['threadId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      type: ChatMessageType.values.firstWhere(
        (item) => item.name == map['type'],
        orElse: () => ChatMessageType.text,
      ),
      text: map['text'] as String? ?? '',
      createdAt: date(map['createdAt']),
      readBy: List<String>.from((map['readBy'] as List?) ?? const []),
      attachmentUrl: map['attachmentUrl'] as String? ?? '',
      attachmentName: map['attachmentName'] as String? ?? '',
      replyToMessageId: map['replyToMessageId'] as String? ?? '',
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'threadId': threadId,
    'senderId': senderId,
    'senderName': senderName,
    'type': type.name,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'readBy': readBy,
    'attachmentUrl': attachmentUrl,
    'attachmentName': attachmentName,
    'replyToMessageId': replyToMessageId,
    'isDeleted': isDeleted,
    'schemaVersion': 1,
  };
}
