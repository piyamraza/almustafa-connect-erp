import 'package:equatable/equatable.dart';

enum TimelineEventType {
  attendance,
  homework,
  fee,
  result,
  notice,
  message,
  leave,
  remark,
  birthday,
  schoolEvent,
  general,
}

class TimelineEventEntity extends Equatable {
  const TimelineEventEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.occurredAt,
    this.studentId = '',
    this.parentId = '',
    this.module = '',
    this.referenceId = '',
    this.createdByUserId = '',
    this.isRead = false,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final TimelineEventType type;
  final String title;
  final String description;
  final DateTime occurredAt;

  final String studentId;
  final String parentId;
  final String module;
  final String referenceId;
  final String createdByUserId;

  final bool isRead;
  final Map<String, dynamic> metadata;

  TimelineEventEntity copyWith({
    String? id,
    TimelineEventType? type,
    String? title,
    String? description,
    DateTime? occurredAt,
    String? studentId,
    String? parentId,
    String? module,
    String? referenceId,
    String? createdByUserId,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return TimelineEventEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      studentId: studentId ?? this.studentId,
      parentId: parentId ?? this.parentId,
      module: module ?? this.module,
      referenceId: referenceId ?? this.referenceId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    type,
    title,
    description,
    occurredAt,
    studentId,
    parentId,
    module,
    referenceId,
    createdByUserId,
    isRead,
    metadata,
  ];
}
