import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/audit_log_entity.dart';

class AuditLogModel extends AuditLogEntity {
  const AuditLogModel({
    required super.id,
    required super.module,
    required super.action,
    required super.recordId,
    required super.userId,
    required super.userName,
    required super.userEmail,
    required super.roleId,
    required super.roleName,
    required super.branchId,
    required super.createdAt,
    super.description,
    super.oldValues,
    super.newValues,
    super.sessionId,
    super.deviceName,
    super.platform,
    super.ipAddress,
  });

  factory AuditLogModel.fromEntity(AuditLogEntity value) {
    return AuditLogModel(
      id: value.id,
      module: value.module,
      action: value.action,
      recordId: value.recordId,
      description: value.description,
      userId: value.userId,
      userName: value.userName,
      userEmail: value.userEmail,
      roleId: value.roleId,
      roleName: value.roleName,
      branchId: value.branchId,
      oldValues: value.oldValues,
      newValues: value.newValues,
      sessionId: value.sessionId,
      deviceName: value.deviceName,
      platform: value.platform,
      ipAddress: value.ipAddress,
      createdAt: value.createdAt,
    );
  }

  factory AuditLogModel.fromMap(String id, Map<String, dynamic> map) {
    return AuditLogModel(
      id: id,
      module: map['module'] as String? ?? '',
      action: AuditAction.values.firstWhere(
        (item) => item.name == map['action'],
        orElse: () => AuditAction.other,
      ),
      recordId: map['recordId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      roleId: map['roleId'] as String? ?? '',
      roleName: map['roleName'] as String? ?? '',
      branchId: map['branchId'] as String? ?? 'main',
      oldValues: Map<String, dynamic>.from(
        map['oldValues'] as Map? ?? const {},
      ),
      newValues: Map<String, dynamic>.from(
        map['newValues'] as Map? ?? const {},
      ),
      sessionId: map['sessionId'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? '',
      platform: map['platform'] as String? ?? '',
      ipAddress: map['ipAddress'] as String? ?? '',
      createdAt: _date(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'module': module,
    'action': action.name,
    'recordId': recordId,
    'description': description,
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'roleId': roleId,
    'roleName': roleName,
    'branchId': branchId,
    'oldValues': oldValues,
    'newValues': newValues,
    'sessionId': sessionId,
    'deviceName': deviceName,
    'platform': platform,
    'ipAddress': ipAddress,
    'createdAt': Timestamp.fromDate(createdAt),
    'schemaVersion': 1,
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
