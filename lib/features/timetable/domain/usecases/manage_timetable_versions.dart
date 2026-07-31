import '../entities/timetable_version_entity.dart';
import '../repositories/timetable_repository.dart';

class ManageTimetableVersions {
  const ManageTimetableVersions(this._repository);

  final TimetableRepository _repository;

  Future<List<TimetableVersionEntity>> getVersions({
    required String branchId,
    required String academicSession,
  }) {
    return _repository.getTimetableVersions(
      branchId: branchId,
      academicSession: academicSession,
    );
  }

  Future<void> createDraft({
    required String branchId,
    required String academicSession,
    required String name,
  }) async {
    final versions = await getVersions(
      branchId: branchId,
      academicSession: academicSession,
    );
    final entries = await _repository.getAllTimetableEntries(
      branchId: branchId,
      academicSession: academicSession,
    );
    final next = versions.isEmpty
        ? 1
        : versions
                  .map((version) => version.versionNumber)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    final now = DateTime.now();

    await _repository.saveTimetableVersion(
      TimetableVersionEntity(
        id: _repository.generateTimetableVersionId(),
        branchId: branchId,
        academicSession: academicSession,
        name: name.trim().isEmpty ? 'Version $next' : name.trim(),
        versionNumber: next,
        status: TimetableVersionStatus.draft,
        entries: entries,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> publish(TimetableVersionEntity version) {
    return _repository.publishTimetableVersion(version.id);
  }

  Future<void> archive(TimetableVersionEntity version) {
    return _repository.archiveTimetableVersion(version.id);
  }

  Future<void> rollback(TimetableVersionEntity version) {
    return _repository.restoreTimetableVersion(version.id);
  }
}
