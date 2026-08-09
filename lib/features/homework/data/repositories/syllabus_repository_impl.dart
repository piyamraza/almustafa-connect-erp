import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/syllabus_entry_entity.dart';
import '../../domain/repositories/syllabus_repository.dart';
import '../models/syllabus_entry_model.dart';

class SyllabusRepositoryImpl implements SyllabusRepository {
  const SyllabusRepositoryImpl(this._service);

  final FirebaseFirestoreService _service;

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
  Future<void> deleteEntry(String id) =>
      _service.collection(FirestorePaths.syllabusEntries).doc(id).delete();

  @override
  String generateId() =>
      _service.collection(FirestorePaths.syllabusEntries).doc().id;
}
