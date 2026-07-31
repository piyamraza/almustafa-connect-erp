import 'package:equatable/equatable.dart';

enum AcademicCalendarEventType {
  holiday,
  exam,
  schoolActivity,
  meeting,
  vacation,
  deadline,
  other,
}

enum AcademicCalendarAudience {
  wholeSchool,
  students,
  teachers,
  parents,
  selectedClasses,
}

class AcademicCalendarEventEntity extends Equatable {
  AcademicCalendarEventEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.audience,
    required this.startDate,
    required this.endDate,
    required this.isAllDay,
    required this.startMinutes,
    required this.endMinutes,
    required List<String> classIds,
    required this.location,
    required this.academicSession,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : classIds = List<String>.unmodifiable(classIds);

  final String id;
  final String title;
  final String description;
  final AcademicCalendarEventType type;
  final AcademicCalendarAudience audience;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAllDay;
  final int? startMinutes;
  final int? endMinutes;
  final List<String> classIds;
  final String location;
  final String academicSession;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool occursOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  AcademicCalendarEventEntity copyWith({
    String? title,
    String? description,
    AcademicCalendarEventType? type,
    AcademicCalendarAudience? audience,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    int? startMinutes,
    int? endMinutes,
    List<String>? classIds,
    String? location,
    String? academicSession,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return AcademicCalendarEventEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      audience: audience ?? this.audience,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isAllDay: isAllDay ?? this.isAllDay,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      classIds: classIds ?? this.classIds,
      location: location ?? this.location,
      academicSession: academicSession ?? this.academicSession,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    type,
    audience,
    startDate,
    endDate,
    isAllDay,
    startMinutes,
    endMinutes,
    classIds,
    location,
    academicSession,
    isActive,
    createdAt,
    updatedAt,
  ];
}
