import '../../domain/entities/audit_log_entity.dart';
import '../../domain/repositories/audit_repository.dart';
import '../datasources/audit_remote_datasource.dart';
import '../models/audit_log_model.dart';

class AuditRepositoryImpl implements AuditRepository {
  const AuditRepositoryImpl(this._remoteDataSource);

  final AuditRemoteDataSource _remoteDataSource;

  @override
  String generateId() => _remoteDataSource.generateId();

  @override
  Future<void> saveLog(AuditLogEntity log) {
    return _remoteDataSource.save(AuditLogModel.fromEntity(log));
  }

  @override
  Future<List<AuditLogEntity>> getLogs({
    String? module,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 200,
  }) {
    return _remoteDataSource.getLogs(
      module: module,
      userId: userId,
      fromDate: fromDate,
      toDate: toDate,
      limit: limit,
    );
  }
}
