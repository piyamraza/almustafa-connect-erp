import '../../domain/entities/timeline_event_entity.dart';
import '../../domain/repositories/timeline_repository.dart';
import '../../domain/services/timeline_service.dart';

class TimelineServiceImpl implements TimelineService {
  const TimelineServiceImpl(this._repository);

  final TimelineRepository _repository;

  @override
  Future<List<TimelineEventEntity>> loadStudentTimeline({
    required String studentId,
  }) {
    return _repository.getTimeline(studentId: studentId);
  }

  @override
  Future<void> publishEvent(TimelineEventEntity event) {
    return _repository.saveEvent(event);
  }

  @override
  Future<void> markEventAsRead(String eventId) {
    return _repository.markAsRead(eventId);
  }

  @override
  Future<void> removeEvent(String eventId) {
    return _repository.deleteEvent(eventId);
  }
}
