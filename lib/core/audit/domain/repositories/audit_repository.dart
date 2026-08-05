import '../entities/audit_log_entity.dart';

abstract class AuditRepository {
  String generateId();

  Future<void> saveLog(AuditLogEntity log);

  Future<List<AuditLogEntity>> getLogs({
    String? module,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 200,
  });

  Future<int> deleteAllLogs();
}
