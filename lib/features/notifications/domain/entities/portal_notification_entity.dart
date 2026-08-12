import 'package:equatable/equatable.dart';

enum PortalRecipientType { teacher, parent, admin }

enum PortalNotificationType {
  homeworkQuestion,
  homeworkReply,
  attendance,
  homework,
  syllabus,
  exam,
  result,
  fee,
  notice,
  leave,
  birthday,
  chat,
  general,
}

class PortalNotificationEntity extends Equatable {
  const PortalNotificationEntity({
    required this.id,
    required this.recipientType,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.type,
    required this.referenceId,
    required this.studentId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final PortalRecipientType recipientType;
  final String recipientId;
  final String title;
  final String message;
  final PortalNotificationType type;
  final String referenceId;
  final String studentId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  @override
  List<Object?> get props => [
    id,
    recipientType,
    recipientId,
    title,
    message,
    type,
    referenceId,
    studentId,
    isRead,
    createdAt,
    readAt,
  ];
}
