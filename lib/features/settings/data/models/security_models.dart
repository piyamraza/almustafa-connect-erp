import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/login_history_entity.dart';
import '../../domain/entities/security_session_entity.dart';

DateTime _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse('$value') ?? DateTime.now();
}

class SecuritySessionModel extends SecuritySessionEntity {
  const SecuritySessionModel({
    required super.id,
    required super.userId,
    required super.deviceName,
    required super.platform,
    required super.lastActiveAt,
    required super.createdAt,
    required super.isCurrent,
    required super.isRevoked,
    super.ipAddress,
    super.appVersion,
  });

  factory SecuritySessionModel.fromMap(Map<String, dynamic> map) {
    return SecuritySessionModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? '',
      platform: map['platform'] as String? ?? '',
      lastActiveAt: _date(map['lastActiveAt']),
      createdAt: _date(map['createdAt']),
      isCurrent: map['isCurrent'] as bool? ?? false,
      isRevoked: map['isRevoked'] as bool? ?? false,
      ipAddress: map['ipAddress'] as String? ?? '',
      appVersion: map['appVersion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'deviceName': deviceName,
    'platform': platform,
    'lastActiveAt': lastActiveAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'isCurrent': isCurrent,
    'isRevoked': isRevoked,
    'ipAddress': ipAddress,
    'appVersion': appVersion,
    'schemaVersion': 1,
  };
}

class LoginHistoryModel extends LoginHistoryEntity {
  const LoginHistoryModel({
    required super.id,
    required super.userId,
    required super.activityType,
    required super.occurredAt,
    required super.success,
    super.deviceName,
    super.platform,
    super.ipAddress,
    super.details,
  });

  factory LoginHistoryModel.fromMap(Map<String, dynamic> map) {
    return LoginHistoryModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      activityType: LoginActivityType.values.firstWhere(
        (item) => item.name == map['activityType'],
        orElse: () => LoginActivityType.login,
      ),
      occurredAt: _date(map['occurredAt']),
      success: map['success'] as bool? ?? true,
      deviceName: map['deviceName'] as String? ?? '',
      platform: map['platform'] as String? ?? '',
      ipAddress: map['ipAddress'] as String? ?? '',
      details: map['details'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'activityType': activityType.name,
    'occurredAt': occurredAt.toIso8601String(),
    'success': success,
    'deviceName': deviceName,
    'platform': platform,
    'ipAddress': ipAddress,
    'details': details,
    'schemaVersion': 1,
  };
}
