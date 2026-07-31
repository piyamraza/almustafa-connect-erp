import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/academic_calendar_event_entity.dart';
import '../../domain/repositories/academic_calendar_repository.dart';
import '../models/academic_calendar_event_model.dart';

class AcademicCalendarRepositoryImpl implements AcademicCalendarRepository {
  const AcademicCalendarRepositoryImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<AcademicCalendarEventEntity>> getEvents({
    required String academicSession,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.academicCalendarEvents)
        .get();

    final values =
        snapshot.docs
            .map(
              (document) => AcademicCalendarEventModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .where(
              (item) =>
                  item.academicSession == academicSession &&
                  (isActive == null || item.isActive == isActive) &&
                  (startDate == null || !item.endDate.isBefore(startDate)) &&
                  (endDate == null || !item.startDate.isAfter(endDate)),
            )
            .toList()
          ..sort((a, b) {
            final date = a.startDate.compareTo(b.startDate);
            if (date != 0) return date;
            return a.title.compareTo(b.title);
          });

    return List<AcademicCalendarEventEntity>.unmodifiable(values);
  }

  @override
  Future<void> saveEvent(AcademicCalendarEventEntity event) async {
    if (event.title.trim().isEmpty) {
      throw StateError('Event title is required.');
    }
    if (event.endDate.isBefore(event.startDate)) {
      throw StateError('End date cannot be before start date.');
    }
    if (!event.isAllDay &&
        (event.startMinutes == null ||
            event.endMinutes == null ||
            event.startMinutes! >= event.endMinutes!)) {
      throw StateError('Enter a valid event start and end time.');
    }
    if (event.audience == AcademicCalendarAudience.selectedClasses &&
        event.classIds.isEmpty) {
      throw StateError('Select at least one class.');
    }

    await _firestoreService
        .collection(FirestorePaths.academicCalendarEvents)
        .doc(event.id)
        .set(AcademicCalendarEventModel.fromEntity(event).toMap());
  }

  @override
  Future<void> deleteEvent(String id) {
    return _firestoreService
        .collection(FirestorePaths.academicCalendarEvents)
        .doc(id)
        .delete();
  }

  @override
  String generateId() {
    return _firestoreService
        .collection(FirestorePaths.academicCalendarEvents)
        .doc()
        .id;
  }
}
