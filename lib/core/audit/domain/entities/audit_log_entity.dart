import 'package:equatable/equatable.dart';

enum AuditAction {
  create,
  update,
  delete,
  restore,
  approve,
  reject,
  login,
  logout,
  view,
  print,
  export,
  send,
  collectPayment,
  other,
}

class AuditLogEntity extends Equatable {
  const AuditLogEntity({
    required this.id,
    required this.module,
    required this.action,
    required this.recordId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.roleId,
    required this.roleName,
    required this.branchId,
    required this.createdAt,
    this.description = '',
    this.oldValues = const {},
    this.newValues = const {},
    this.sessionId = '',
    this.deviceName = '',
    this.platform = '',
    this.ipAddress = '',
  });

  final String id;
  final String module;
  final AuditAction action;
  final String recordId;
  final String description;
  final String userId;
  final String userName;
  final String userEmail;
  final String roleId;
  final String roleName;
  final String branchId;
  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;
  final String sessionId;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    module,
    action,
    recordId,
    description,
    userId,
    userName,
    userEmail,
    roleId,
    roleName,
    branchId,
    oldValues,
    newValues,
    sessionId,
    deviceName,
    platform,
    ipAddress,
    createdAt,
  ];
}
