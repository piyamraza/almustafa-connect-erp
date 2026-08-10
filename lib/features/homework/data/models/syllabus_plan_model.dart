import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/syllabus_plan_entity.dart';

class SyllabusPlanModel extends SyllabusPlanEntity {
  const SyllabusPlanModel({
    required super.id,
    required super.academicSession,
    required super.title,
    required super.isPublished,
    required super.createdAt,
    required super.updatedAt,
    super.publishedAt,
  });

  factory SyllabusPlanModel.fromEntity(SyllabusPlanEntity value) =>
      SyllabusPlanModel(
        id: value.id,
        academicSession: value.academicSession,
        title: value.title,
        isPublished: value.isPublished,
        createdAt: value.createdAt,
        updatedAt: value.updatedAt,
        publishedAt: value.publishedAt,
      );

  factory SyllabusPlanModel.fromMap(Map<String, dynamic> map) =>
      SyllabusPlanModel(
        id: map['id'] as String? ?? '',
        academicSession: map['academicSession'] as String? ?? '',
        title: map['title'] as String? ?? '',
        isPublished: map['isPublished'] as bool? ?? false,
        createdAt: _date(map['createdAt']),
        updatedAt: _date(map['updatedAt']),
        publishedAt: map['publishedAt'] == null
            ? null
            : _date(map['publishedAt']),
      );

  Map<String, dynamic> toMap() => {
    'academicSession': academicSession,
    'title': title,
    'isPublished': isPublished,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'publishedAt': publishedAt == null
        ? null
        : Timestamp.fromDate(publishedAt!),
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
