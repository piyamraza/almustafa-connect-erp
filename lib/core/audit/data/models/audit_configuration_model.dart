import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/audit_configuration_entity.dart';

class AuditConfigurationModel extends AuditConfigurationEntity {
  const AuditConfigurationModel({
    required super.enabled,
    required super.level,
    required super.enabledModules,
    required super.retentionPeriod,
    required super.updatedAt,
    super.updatedBy,
    super.temporaryDetailedLoggingExpiresAt,
    super.temporaryDetailedLoggingFallbackLevel,
  });

  factory AuditConfigurationModel.fromEntity(AuditConfigurationEntity entity) {
    return AuditConfigurationModel(
      enabled: entity.enabled,
      level: entity.level,
      enabledModules: entity.enabledModules,
      retentionPeriod: entity.retentionPeriod,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
      temporaryDetailedLoggingExpiresAt:
          entity.temporaryDetailedLoggingExpiresAt,
      temporaryDetailedLoggingFallbackLevel:
          entity.temporaryDetailedLoggingFallbackLevel,
    );
  }

  factory AuditConfigurationModel.fromMap(Map<String, dynamic> map) {
    final defaultConfiguration =
        AuditConfigurationEntity.defaultConfiguration();

    return AuditConfigurationModel(
      enabled: map['enabled'] as bool? ?? defaultConfiguration.enabled,
      level: _parseLogLevel(map['level'], defaultConfiguration.level),
      enabledModules: _parseEnabledModules(
        map['enabledModules'],
        defaultConfiguration.enabledModules,
      ),
      retentionPeriod: _parseRetentionPeriod(
        map['retentionPeriod'],
        defaultConfiguration.retentionPeriod,
      ),
      updatedAt: _parseDateTime(map['updatedAt']),
      updatedBy: (map['updatedBy'] as String? ?? '').trim(),
      temporaryDetailedLoggingExpiresAt: _parseNullableDateTime(
        map['temporaryDetailedLoggingExpiresAt'],
      ),
      temporaryDetailedLoggingFallbackLevel: _parseLogLevel(
        map['temporaryDetailedLoggingFallbackLevel'],
        AuditLogLevel.critical,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'level': level.name,
      'enabledModules': enabledModules.toList()..sort(),
      'retentionPeriod': retentionPeriod.name,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'temporaryDetailedLoggingExpiresAt':
          temporaryDetailedLoggingExpiresAt == null
          ? null
          : Timestamp.fromDate(temporaryDetailedLoggingExpiresAt!),
      'temporaryDetailedLoggingFallbackLevel':
          temporaryDetailedLoggingFallbackLevel.name,
    };
  }

  static AuditLogLevel _parseLogLevel(dynamic value, AuditLogLevel fallback) {
    final name = value?.toString().trim();

    for (final level in AuditLogLevel.values) {
      if (level.name == name) {
        return level;
      }
    }

    return fallback;
  }

  static AuditRetentionPeriod _parseRetentionPeriod(
    dynamic value,
    AuditRetentionPeriod fallback,
  ) {
    final name = value?.toString().trim();

    for (final period in AuditRetentionPeriod.values) {
      if (period.name == name) {
        return period;
      }
    }

    return fallback;
  }

  static Set<String> _parseEnabledModules(dynamic value, Set<String> fallback) {
    if (value is! Iterable) {
      return Set<String>.unmodifiable(fallback);
    }

    final modules = value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet();

    if (modules.isEmpty) {
      return Set<String>.unmodifiable(fallback);
    }

    return Set<String>.unmodifiable(modules);
  }

  static DateTime _parseDateTime(dynamic value) {
    return _parseNullableDateTime(value) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
