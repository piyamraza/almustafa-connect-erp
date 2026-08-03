import '../entities/backup_record_entity.dart';
import '../entities/restore_request_entity.dart';
import '../repositories/backup_repository.dart';

class BackupRestoreData {
  const BackupRestoreData(this.backups, this.restoreRequests);

  final List<BackupRecordEntity> backups;
  final List<RestoreRequestEntity> restoreRequests;
}

class GetBackupRestoreData {
  const GetBackupRestoreData(this._repository);

  final BackupRepository _repository;

  Future<BackupRestoreData> call() async {
    final values = await Future.wait<Object>([
      _repository.getBackups(),
      _repository.getRestoreRequests(),
    ]);

    return BackupRestoreData(
      values[0] as List<BackupRecordEntity>,
      values[1] as List<RestoreRequestEntity>,
    );
  }
}

class RequestBackup {
  const RequestBackup(this._repository);

  final BackupRepository _repository;

  Future<void> call(String requestedBy, String notes) =>
      _repository.requestBackup(requestedBy, notes);
}

class RequestRestore {
  const RequestRestore(this._repository);

  final BackupRepository _repository;

  Future<void> call(RestoreRequestEntity request) {
    if (request.confirmationText.trim() != 'RESTORE') {
      throw ArgumentError('Type RESTORE to confirm.');
    }
    return _repository.requestRestore(request);
  }
}
