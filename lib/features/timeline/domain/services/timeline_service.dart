import '../entities/timeline_event_entity.dart';

abstract class TimelineService {
  Future<List<TimelineEventEntity>> loadStudentTimeline({
    required String studentId,
  });

  Future<void> publishEvent(TimelineEventEntity event);

  Future<void> markEventAsRead(String eventId);

  Future<void> removeEvent(String eventId);
}
