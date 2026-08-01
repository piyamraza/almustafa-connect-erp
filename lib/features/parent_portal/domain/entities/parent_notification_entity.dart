import 'package:equatable/equatable.dart';

enum ParentNotificationType {
  attendance,
  homework,
  fee,
  exam,
  result,
  notice,
  calendar,
  general,
}

class ParentNotificationEntity extends Equatable {
  const ParentNotificationEntity({
    required this.id,
    required this.parentId,
    required this.studentId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.readAt,
    required this.referenceId,
    required this.actionRoute,
  });

  final String id;
  final String parentId;
  final String studentId;
  final String title;
  final String message;
  final ParentNotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String referenceId;
  final String actionRoute;

  ParentNotificationEntity copyWith({bool? isRead, DateTime? readAt}) {
    return ParentNotificationEntity(
      id: id,
      parentId: parentId,
      studentId: studentId,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      referenceId: referenceId,
      actionRoute: actionRoute,
    );
  }

  @override
  List<Object?> get props => [
    id,
    parentId,
    studentId,
    title,
    message,
    type,
    isRead,
    createdAt,
    readAt,
    referenceId,
    actionRoute,
  ];
}
