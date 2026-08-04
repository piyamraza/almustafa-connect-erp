import '../entities/audit_context.dart';
import '../entities/audit_log_entity.dart';

abstract class AuditService {
  String get sessionId;

  AuditContext buildContext({String? roleId, String? roleName});

  Future<void> log({
    required String module,
    required AuditAction action,
    required String recordId,
    String description = '',
    Map<String, dynamic> oldValues = const {},
    Map<String, dynamic> newValues = const {},
    String? roleId,
    String? roleName,
  });

  Future<void> logCreate({
    required String module,
    required String recordId,
    String description = '',
    Map<String, dynamic> newValues = const {},
    String? roleId,
    String? roleName,
  });

  Future<void> logUpdate({
    required String module,
    required String recordId,
    String description = '',
    Map<String, dynamic> oldValues = const {},
    Map<String, dynamic> newValues = const {},
    String? roleId,
    String? roleName,
  });

  Future<void> logDelete({
    required String module,
    required String recordId,
    String description = '',
    Map<String, dynamic> oldValues = const {},
    String? roleId,
    String? roleName,
  });

  Future<void> logRestore({
    required String module,
    required String recordId,
    String description = '',
    Map<String, dynamic> newValues = const {},
    String? roleId,
    String? roleName,
  });
}
