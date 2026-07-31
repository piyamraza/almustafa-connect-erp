import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/academic_calendar_event_entity.dart';

class AcademicCalendarEventModel extends AcademicCalendarEventEntity {
  AcademicCalendarEventModel({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    required super.audience,
    required super.startDate,
    required super.endDate,
    required super.isAllDay,
    required super.startMinutes,
    required super.endMinutes,
    required super.classIds,
    required super.location,
    required super.academicSession,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AcademicCalendarEventModel.fromEntity(
    AcademicCalendarEventEntity entity,
  ) {
    return AcademicCalendarEventModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      type: entity.type,
      audience: entity.audience,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isAllDay: entity.isAllDay,
      startMinutes: entity.startMinutes,
      endMinutes: entity.endMinutes,
      classIds: entity.classIds,
      location: entity.location,
      academicSession: entity.academicSession,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory AcademicCalendarEventModel.fromMap(Map<String, dynamic> map) {
    return AcademicCalendarEventModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: AcademicCalendarEventType.values.firstWhere(
        (item) => item.name == map['type'],
        orElse: () => AcademicCalendarEventType.other,
      ),
      audience: AcademicCalendarAudience.values.firstWhere(
        (item) => item.name == map['audience'],
        orElse: () => AcademicCalendarAudience.wholeSchool,
      ),
      startDate: _date(map['startDate']),
      endDate: _date(map['endDate']),
      isAllDay: map['isAllDay'] as bool? ?? true,
      startMinutes: (map['startMinutes'] as num?)?.toInt(),
      endMinutes: (map['endMinutes'] as num?)?.toInt(),
      classIds: (map['classIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      location: map['location'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'type': type.name,
    'audience': audience.name,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'isAllDay': isAllDay,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'classIds': classIds,
    'location': location,
    'academicSession': academicSession,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
