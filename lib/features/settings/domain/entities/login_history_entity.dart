import 'package:equatable/equatable.dart';

enum LoginActivityType {
  login,
  logout,
  failedLogin,
  passwordChanged,
  sessionRevoked,
}

class LoginHistoryEntity extends Equatable {
  const LoginHistoryEntity({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.occurredAt,
    required this.success,
    this.deviceName = '',
    this.platform = '',
    this.ipAddress = '',
    this.details = '',
  });

  final String id;
  final String userId;
  final LoginActivityType activityType;
  final DateTime occurredAt;
  final bool success;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final String details;

  @override
  List<Object?> get props => [
    id,
    userId,
    activityType,
    occurredAt,
    success,
    deviceName,
    platform,
    ipAddress,
    details,
  ];
}
