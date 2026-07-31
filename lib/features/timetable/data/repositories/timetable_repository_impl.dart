import '../../domain/entities/class_timetable_entry_entity.dart';
import '../../domain/entities/manual_timetable_change_entity.dart';
import '../../domain/entities/timetable_version_entity.dart';
import '../../domain/entities/timetable_configuration_entity.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../datasources/timetable_remote_datasource.dart';
import '../models/class_timetable_entry_model.dart';
import '../models/timetable_configuration_model.dart';

class TimetableRepositoryImpl implements TimetableRepository {
  const TimetableRepositoryImpl(this._remoteDataSource);

  final TimetableRemoteDataSource _remoteDataSource;

  @override
  Future<TimetableConfigurationEntity?> getConfiguration({
    required String branchId,
    required String academicSession,
  }) {
    return _remoteDataSource.getConfiguration(
      branchId: branchId,
      academicSession: academicSession,
    );
  }

  @override
  Future<void> saveConfiguration(TimetableConfigurationEntity configuration) {
    return _remoteDataSource.saveConfiguration(
      TimetableConfigurationModel.fromEntity(configuration),
    );
  }

  @override
  String generateConfigurationId() {
    return _remoteDataSource.generateConfigurationId();
  }

  @override
  Future<List<TimetableVersionEntity>> getTimetableVersions({
    required String branchId,
    required String academicSession,
  }) {
    return _remoteDataSource.getTimetableVersions(
      branchId: branchId,
      academicSession: academicSession,
    );
  }

  @override
  Future<void> saveTimetableVersion(TimetableVersionEntity version) {
    return _remoteDataSource.saveTimetableVersion(version);
  }

  @override
  Future<void> publishTimetableVersion(String versionId) {
    return _remoteDataSource.publishTimetableVersion(versionId);
  }

  @override
  Future<void> archiveTimetableVersion(String versionId) {
    return _remoteDataSource.archiveTimetableVersion(versionId);
  }

  @override
  Future<void> restoreTimetableVersion(String versionId) {
    return _remoteDataSource.restoreTimetableVersion(versionId);
  }

  @override
  String generateTimetableVersionId() {
    return _remoteDataSource.generateTimetableVersionId();
  }

  @override
  Future<void> applyManualTimetableChanges(ManualTimetableChangeSet changes) {
    return _remoteDataSource.applyManualTimetableChanges(changes);
  }

  @override
  Future<List<ClassTimetableEntryEntity>> getAllTimetableEntries({
    required String branchId,
    required String academicSession,
  }) {
    return _remoteDataSource.getAllTimetableEntries(
      branchId: branchId,
      academicSession: academicSession,
    );
  }

  @override
  Future<List<ClassTimetableEntryEntity>> getClassTimetable({
    required String branchId,
    required String academicSession,
    required String classId,
    required String sectionId,
  }) {
    return _remoteDataSource.getClassTimetable(
      branchId: branchId,
      academicSession: academicSession,
      classId: classId,
      sectionId: sectionId,
    );
  }

  @override
  Future<List<ClassTimetableEntryEntity>> getTeacherTimetable({
    required String branchId,
    required String academicSession,
    required String teacherId,
  }) {
    return _remoteDataSource.getTeacherTimetable(
      branchId: branchId,
      academicSession: academicSession,
      teacherId: teacherId,
    );
  }

  @override
  Future<List<ClassTimetableEntryEntity>> getDayTimetable({
    required String branchId,
    required String academicSession,
    required int weekday,
  }) {
    return _remoteDataSource.getDayTimetable(
      branchId: branchId,
      academicSession: academicSession,
      weekday: weekday,
    );
  }

  @override
  Future<void> saveClassTimetableEntry(ClassTimetableEntryEntity entry) {
    return _remoteDataSource.saveClassTimetableEntry(
      ClassTimetableEntryModel.fromEntity(entry),
    );
  }

  @override
  Future<void> deleteClassTimetableEntry(String entryId) {
    return _remoteDataSource.deleteClassTimetableEntry(entryId);
  }

  @override
  String generateClassTimetableEntryId() {
    return _remoteDataSource.generateClassTimetableEntryId();
  }
}
