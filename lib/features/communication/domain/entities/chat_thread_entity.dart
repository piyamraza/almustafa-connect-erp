import 'package:equatable/equatable.dart';

enum ChatThreadType { adminTeacher, teacherParent, custom }

class ChatThreadEntity extends Equatable {
  const ChatThreadEntity({
    required this.id,
    required this.type,
    required this.participantIds,
    required this.participantNames,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.title = '',
    this.lastMessage = '',
    this.lastMessageAt,
    this.isArchived = false,
  });

  final String id;
  final ChatThreadType type;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final bool isArchived;

  @override
  List<Object?> get props => [
    id,
    type,
    participantIds,
    participantNames,
    createdBy,
    createdAt,
    updatedAt,
    title,
    lastMessage,
    lastMessageAt,
    isArchived,
  ];
}
