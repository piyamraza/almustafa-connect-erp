import '../entities/backup_record_entity.dart';
import '../entities/restore_request_entity.dart';

abstract class BackupRepository {
  Future<List<BackupRecordEntity>> getBackups();
  Future<List<RestoreRequestEntity>> getRestoreRequests();
  Future<void> requestBackup(String requestedBy, String notes);
  Future<void> requestRestore(RestoreRequestEntity request);
}
