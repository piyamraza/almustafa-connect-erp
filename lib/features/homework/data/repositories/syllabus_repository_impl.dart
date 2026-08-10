import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/syllabus_entry_entity.dart';
import '../../domain/entities/syllabus_plan_entity.dart';
import '../../domain/repositories/syllabus_repository.dart';
import '../models/syllabus_entry_model.dart';
import '../models/syllabus_plan_model.dart';

class SyllabusRepositoryImpl implements SyllabusRepository {
  const SyllabusRepositoryImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<SyllabusPlanEntity>> getPlans({
    required String academicSession,
    bool publishedOnly = false,
  }) async {
    final collection = _service.collection(FirestorePaths.syllabusPlans);
    final snapshot = publishedOnly
        ? await collection.where('isPublished', isEqualTo: true).get()
        : await collection.get();
    final values =
        snapshot.docs
            .map(
              (doc) => SyllabusPlanModel.fromMap({...doc.data(), 'id': doc.id}),
            )
            .where(
              (item) =>
                  item.academicSession == academicSession &&
                  (!publishedOnly || item.isPublished),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(values);
  }

  @override
  Future<void> savePlan(SyllabusPlanEntity plan) {
    if (plan.title.trim().isEmpty) {
      throw StateError('Syllabus name is required.');
    }
    return _service
        .collection(FirestorePaths.syllabusPlans)
        .doc(plan.id)
        .set(SyllabusPlanModel.fromEntity(plan).toMap());
  }

  @override
  Future<List<SyllabusEntryEntity>> getEntries({
    required String academicSession,
    String? syllabusTitle,
  }) async {
    final snapshot = await _service
        .collection(FirestorePaths.syllabusEntries)
        .get();
    final title = syllabusTitle?.trim().toLowerCase();
    final values =
        snapshot.docs
            .map(
              (doc) =>
                  SyllabusEntryModel.fromMap({...doc.data(), 'id': doc.id}),
            )
            .where(
              (item) =>
                  item.academicSession == academicSession &&
                  (title == null ||
                      title.isEmpty ||
                      item.syllabusTitle.trim().toLowerCase() == title),
            )
            .toList()
          ..sort((a, b) => a.subjectName.compareTo(b.subjectName));
    return List.unmodifiable(values);
  }

  @override
  Future<void> saveEntry(SyllabusEntryEntity entry) {
    if (entry.syllabusTitle.trim().isEmpty) {
      throw StateError('Syllabus title is required.');
    }
    if (entry.content.trim().isEmpty) {
      throw StateError('Syllabus content is required.');
    }
    return _service
        .collection(FirestorePaths.syllabusEntries)
        .doc(entry.id)
        .set(SyllabusEntryModel.fromEntity(entry).toMap());
  }

  @override
  Future<List<SyllabusEntryEntity>> getEntriesForPlan(String planId) async {
    final snapshot = await _service
        .collection(FirestorePaths.syllabusEntries)
        .where('planId', isEqualTo: planId)
        .get();
    final values =
        snapshot.docs
            .map(
              (doc) =>
                  SyllabusEntryModel.fromMap({...doc.data(), 'id': doc.id}),
            )
            .toList()
          ..sort((a, b) => a.subjectName.compareTo(b.subjectName));
    return List.unmodifiable(values);
  }

  @override
  Future<void> deleteEntry(String id) =>
      _service.collection(FirestorePaths.syllabusEntries).doc(id).delete();

  @override
  String generateId() =>
      _service.collection(FirestorePaths.syllabusEntries).doc().id;

  @override
  String generatePlanId() =>
      _service.collection(FirestorePaths.syllabusPlans).doc().id;
}
