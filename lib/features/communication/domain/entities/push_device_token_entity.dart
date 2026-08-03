import 'package:equatable/equatable.dart';

enum PushDevicePlatform { android, ios, web, macos, windows, unknown }

class PushDeviceTokenEntity extends Equatable {
  const PushDeviceTokenEntity({
    required this.id,
    required this.userId,
    required this.token,
    required this.platform,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deviceName = '',
  });

  final String id;
  final String userId;
  final String token;
  final PushDevicePlatform platform;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String deviceName;

  @override
  List<Object?> get props => [
    id,
    userId,
    token,
    platform,
    isActive,
    createdAt,
    updatedAt,
    deviceName,
  ];
}
