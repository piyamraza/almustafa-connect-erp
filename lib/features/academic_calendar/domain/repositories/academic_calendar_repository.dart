import '../entities/academic_calendar_event_entity.dart';

abstract class AcademicCalendarRepository {
  Future<List<AcademicCalendarEventEntity>> getEvents({
    required String academicSession,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  });

  Future<void> saveEvent(AcademicCalendarEventEntity event);

  Future<void> deleteEvent(String id);

  String generateId();
}
