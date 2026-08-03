import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/push_device_token_entity.dart';

class PushDeviceTokenModel extends PushDeviceTokenEntity {
  const PushDeviceTokenModel({
    required super.id,
    required super.userId,
    required super.token,
    required super.platform,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.deviceName,
  });

  factory PushDeviceTokenModel.fromEntity(PushDeviceTokenEntity e) =>
      PushDeviceTokenModel(
        id: e.id,
        userId: e.userId,
        token: e.token,
        platform: e.platform,
        isActive: e.isActive,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deviceName: e.deviceName,
      );

  factory PushDeviceTokenModel.fromMap(Map<String, dynamic> map) {
    DateTime d(dynamic v) => v is Timestamp
        ? v.toDate()
        : v is DateTime
        ? v
        : DateTime.tryParse('$v') ?? DateTime.now();
    return PushDeviceTokenModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      token: map['token'] as String? ?? '',
      platform: PushDevicePlatform.values.firstWhere(
        (x) => x.name == map['platform'],
        orElse: () => PushDevicePlatform.unknown,
      ),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: d(map['createdAt']),
      updatedAt: d(map['updatedAt']),
      deviceName: map['deviceName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'token': token,
    'platform': platform.name,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deviceName': deviceName,
    'schemaVersion': 1,
  };
}
