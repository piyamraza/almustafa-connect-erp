import 'package:equatable/equatable.dart';

class SecuritySessionEntity extends Equatable {
  const SecuritySessionEntity({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.platform,
    required this.lastActiveAt,
    required this.createdAt,
    required this.isCurrent,
    required this.isRevoked,
    this.ipAddress = '',
    this.appVersion = '',
  });

  final String id;
  final String userId;
  final String deviceName;
  final String platform;
  final DateTime lastActiveAt;
  final DateTime createdAt;
  final bool isCurrent;
  final bool isRevoked;
  final String ipAddress;
  final String appVersion;

  @override
  List<Object?> get props => [
    id,
    userId,
    deviceName,
    platform,
    lastActiveAt,
    createdAt,
    isCurrent,
    isRevoked,
    ipAddress,
    appVersion,
  ];
}
