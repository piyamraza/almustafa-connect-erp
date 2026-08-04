import '../entities/timeline_event_entity.dart';

abstract class TimelineRepository {
  Future<List<TimelineEventEntity>> getTimeline({required String studentId});

  Future<void> saveEvent(TimelineEventEntity event);

  Future<void> markAsRead(String eventId);

  Future<void> deleteEvent(String eventId);
}
