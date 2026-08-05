import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/audit_configuration_entity.dart';

class AuditConfigurationModel extends AuditConfigurationEntity {
  const AuditConfigurationModel({
    required super.level,
    required super.updatedAt,
    super.updatedBy,
  });

  factory AuditConfigurationModel.fromEntity(AuditConfigurationEntity entity) {
    return AuditConfigurationModel(
      level: entity.level,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
    );
  }

  factory AuditConfigurationModel.fromMap(Map<String, dynamic> map) {
    return AuditConfigurationModel(
      level: _parseLevel(map['level']),
      updatedAt: _parseDateTime(map['updatedAt']),
      updatedBy: (map['updatedBy'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level.name,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  static AuditLogLevel _parseLevel(dynamic value) {
    final name = value?.toString().trim();

    for (final level in AuditLogLevel.values) {
      if (level.name == name) {
        return level;
      }
    }

    return AuditLogLevel.critical;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
