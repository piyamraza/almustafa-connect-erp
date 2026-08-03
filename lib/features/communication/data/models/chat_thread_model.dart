import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat_thread_entity.dart';

class ChatThreadModel extends ChatThreadEntity {
  const ChatThreadModel({
    required super.id,
    required super.type,
    required super.participantIds,
    required super.participantNames,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.title,
    super.lastMessage,
    super.lastMessageAt,
    super.isArchived,
  });

  factory ChatThreadModel.fromEntity(ChatThreadEntity entity) {
    return ChatThreadModel(
      id: entity.id,
      type: entity.type,
      participantIds: entity.participantIds,
      participantNames: entity.participantNames,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      title: entity.title,
      lastMessage: entity.lastMessage,
      lastMessageAt: entity.lastMessageAt,
      isArchived: entity.isArchived,
    );
  }

  factory ChatThreadModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return ChatThreadModel(
      id: map['id'] as String? ?? '',
      type: ChatThreadType.values.firstWhere(
        (item) => item.name == map['type'],
        orElse: () => ChatThreadType.custom,
      ),
      participantIds: List<String>.from(
        (map['participantIds'] as List?) ?? const [],
      ),
      participantNames: Map<String, String>.from(
        (map['participantNames'] as Map?) ?? const {},
      ),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
      title: map['title'] as String? ?? '',
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageAt: map['lastMessageAt'] == null
          ? null
          : date(map['lastMessageAt']),
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'participantIds': participantIds,
    'participantNames': participantNames,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'title': title,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt?.toIso8601String(),
    'isArchived': isArchived,
    'schemaVersion': 1,
  };
}
