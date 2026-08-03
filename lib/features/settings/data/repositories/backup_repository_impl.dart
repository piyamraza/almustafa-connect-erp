import '../../domain/entities/backup_record_entity.dart';
import '../../domain/entities/restore_request_entity.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/backup_remote_datasource.dart';

class BackupRepositoryImpl implements BackupRepository {
  const BackupRepositoryImpl(this._source);

  final BackupRemoteDataSource _source;

  @override
  Future<List<BackupRecordEntity>> getBackups() => _source.getBackups();

  @override
  Future<List<RestoreRequestEntity>> getRestoreRequests() =>
      _source.getRestoreRequests();

  @override
  Future<void> requestBackup(String requestedBy, String notes) =>
      _source.requestBackup(requestedBy, notes);

  @override
  Future<void> requestRestore(RestoreRequestEntity request) =>
      _source.requestRestore(request);
}
