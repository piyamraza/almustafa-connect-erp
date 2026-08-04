import 'package:equatable/equatable.dart';

class AuditContext extends Equatable {
  const AuditContext({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.roleId,
    required this.roleName,
    required this.branchId,
    required this.sessionId,
    required this.platform,
    this.deviceName = '',
    this.ipAddress = '',
  });

  final String userId;
  final String userName;
  final String userEmail;

  final String roleId;
  final String roleName;

  final String branchId;
  final String sessionId;

  final String platform;
  final String deviceName;
  final String ipAddress;

  @override
  List<Object?> get props => [
    userId,
    userName,
    userEmail,
    roleId,
    roleName,
    branchId,
    sessionId,
    platform,
    deviceName,
    ipAddress,
  ];
}
