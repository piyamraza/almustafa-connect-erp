import 'package:equatable/equatable.dart';

enum ChatMessageType { text, image, document, system }

class ChatMessageEntity extends Equatable {
  const ChatMessageEntity({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.text,
    required this.createdAt,
    required this.readBy,
    this.attachmentUrl = '',
    this.attachmentName = '',
    this.replyToMessageId = '',
    this.isDeleted = false,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String senderName;
  final ChatMessageType type;
  final String text;
  final DateTime createdAt;
  final List<String> readBy;
  final String attachmentUrl;
  final String attachmentName;
  final String replyToMessageId;
  final bool isDeleted;

  bool isReadBy(String userId) => readBy.contains(userId);

  @override
  List<Object?> get props => [
    id,
    threadId,
    senderId,
    senderName,
    type,
    text,
    createdAt,
    readBy,
    attachmentUrl,
    attachmentName,
    replyToMessageId,
    isDeleted,
  ];
}
