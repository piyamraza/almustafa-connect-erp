import '../entities/syllabus_entry_entity.dart';
import '../entities/syllabus_plan_entity.dart';

abstract class SyllabusRepository {
  Future<List<SyllabusPlanEntity>> getPlans({
    required String academicSession,
    bool publishedOnly = false,
  });

  Future<void> savePlan(SyllabusPlanEntity plan);

  Future<List<SyllabusEntryEntity>> getEntries({
    required String academicSession,
    String? syllabusTitle,
  });

  Future<void> saveEntry(SyllabusEntryEntity entry);

  Future<List<SyllabusEntryEntity>> getEntriesForPlan(String planId);

  Future<void> deleteEntry(String id);

  String generateId();

  String generatePlanId();
}
