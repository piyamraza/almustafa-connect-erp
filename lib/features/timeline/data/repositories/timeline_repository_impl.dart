import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/timeline_event_entity.dart';
import '../../domain/repositories/timeline_repository.dart';
import '../models/timeline_event_model.dart';

class TimelineRepositoryImpl implements TimelineRepository {
  const TimelineRepositoryImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<TimelineEventEntity>> getTimeline({
    required String studentId,
  }) async {
    final id = studentId.trim();
    if (id.isEmpty) return const <TimelineEventEntity>[];

    final snapshot = await _firestoreService
        .collection(FirestorePaths.timelineEvents)
        .where('studentId', isEqualTo: id)
        .get();

    final events =
        snapshot.docs
            .map(
              (document) => TimelineEventModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return List<TimelineEventEntity>.unmodifiable(events);
  }

  @override
  Future<void> saveEvent(TimelineEventEntity event) async {
    final collection = _firestoreService.collection(
      FirestorePaths.timelineEvents,
    );

    final document = event.id.trim().isEmpty
        ? collection.doc()
        : collection.doc(event.id.trim());

    final model = TimelineEventModel.fromEntity(
      event.copyWith(id: document.id),
    );

    await document.set(model.toMap());
  }

  @override
  Future<void> markAsRead(String eventId) async {
    final id = eventId.trim();
    if (id.isEmpty) return;

    await _firestoreService
        .collection(FirestorePaths.timelineEvents)
        .doc(id)
        .update({'isRead': true});
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    final id = eventId.trim();
    if (id.isEmpty) return;

    await _firestoreService
        .collection(FirestorePaths.timelineEvents)
        .doc(id)
        .delete();
  }
}
