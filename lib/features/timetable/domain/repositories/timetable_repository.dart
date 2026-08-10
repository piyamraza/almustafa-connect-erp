import '../entities/timetable_version_entity.dart';
import '../entities/manual_timetable_change_entity.dart';
import '../entities/class_timetable_entry_entity.dart';
import '../entities/timetable_configuration_entity.dart';

abstract class TimetableRepository {
  Future<TimetableConfigurationEntity?> getConfiguration({
    required String branchId,
    required String academicSession,
    String? classId,
  });

  Future<List<TimetableConfigurationEntity>> getConfigurations({
    required String branchId,
    required String academicSession,
  });

  Future<void> saveConfiguration(TimetableConfigurationEntity configuration);

  String generateConfigurationId();

  Future<List<TimetableVersionEntity>> getTimetableVersions({
    required String branchId,
    required String academicSession,
  });
  Future<void> saveTimetableVersion(TimetableVersionEntity version);
  Future<void> publishTimetableVersion(String versionId);
  Future<void> archiveTimetableVersion(String versionId);
  Future<void> restoreTimetableVersion(String versionId);
  String generateTimetableVersionId();
  Future<void> applyManualTimetableChanges(ManualTimetableChangeSet changes);

  Future<List<ClassTimetableEntryEntity>> getAllTimetableEntries({
    required String branchId,
    required String academicSession,
  });
  Future<List<ClassTimetableEntryEntity>> getClassTimetable({
    required String branchId,
    required String academicSession,
    required String classId,
    required String sectionId,
  });

  Future<List<ClassTimetableEntryEntity>> getTeacherTimetable({
    required String branchId,
    required String academicSession,
    required String teacherId,
  });
  Future<List<ClassTimetableEntryEntity>> getDayTimetable({
    required String branchId,
    required String academicSession,
    required int weekday,
  });
  Future<void> saveClassTimetableEntry(ClassTimetableEntryEntity entry);

  Future<void> deleteClassTimetableEntry(String entryId);

  String generateClassTimetableEntryId();
}
