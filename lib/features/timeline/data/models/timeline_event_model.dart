import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/timeline_event_entity.dart';

class TimelineEventModel extends TimelineEventEntity {
  const TimelineEventModel({
    required super.id,
    required super.type,
    required super.title,
    required super.description,
    required super.occurredAt,
    super.studentId,
    super.parentId,
    super.module,
    super.referenceId,
    super.createdByUserId,
    super.isRead,
    super.metadata,
  });

  factory TimelineEventModel.fromEntity(TimelineEventEntity entity) {
    return TimelineEventModel(
      id: entity.id,
      type: entity.type,
      title: entity.title,
      description: entity.description,
      occurredAt: entity.occurredAt,
      studentId: entity.studentId,
      parentId: entity.parentId,
      module: entity.module,
      referenceId: entity.referenceId,
      createdByUserId: entity.createdByUserId,
      isRead: entity.isRead,
      metadata: entity.metadata,
    );
  }

  factory TimelineEventModel.fromMap(Map<String, dynamic> map) {
    return TimelineEventModel(
      id: map['id'] as String? ?? '',
      type: _type(map['type']),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      occurredAt: _date(map['occurredAt']),
      studentId: map['studentId'] as String? ?? '',
      parentId: map['parentId'] as String? ?? '',
      module: map['module'] as String? ?? '',
      referenceId: map['referenceId'] as String? ?? '',
      createdByUserId: map['createdByUserId'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'title': title,
    'description': description,
    'occurredAt': Timestamp.fromDate(occurredAt),
    'studentId': studentId,
    'parentId': parentId,
    'module': module,
    'referenceId': referenceId,
    'createdByUserId': createdByUserId,
    'isRead': isRead,
    'metadata': metadata,
  };

  static TimelineEventType _type(dynamic value) {
    final name = value?.toString() ?? '';
    return TimelineEventType.values.firstWhere(
      (item) => item.name == name,
      orElse: () => TimelineEventType.general,
    );
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
