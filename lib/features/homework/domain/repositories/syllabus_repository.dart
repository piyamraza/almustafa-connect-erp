import '../entities/syllabus_entry_entity.dart';

abstract class SyllabusRepository {
  Future<List<SyllabusEntryEntity>> getEntries({
    required String academicSession,
    String? syllabusTitle,
  });

  Future<void> saveEntry(SyllabusEntryEntity entry);

  Future<void> deleteEntry(String id);

  String generateId();
}
