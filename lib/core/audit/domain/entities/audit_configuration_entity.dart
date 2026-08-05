import 'package:equatable/equatable.dart';

enum AuditLogLevel { off, critical, standard, detailed }

class AuditConfigurationEntity extends Equatable {
  const AuditConfigurationEntity({
    required this.level,
    required this.updatedAt,
    this.updatedBy = '',
  });

  factory AuditConfigurationEntity.defaultConfiguration() {
    return AuditConfigurationEntity(
      level: AuditLogLevel.critical,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final AuditLogLevel level;
  final DateTime updatedAt;
  final String updatedBy;

  bool get isLoggingEnabled => level != AuditLogLevel.off;

  bool allowsLevel(AuditLogLevel requiredLevel) {
    return isLoggingEnabled && level.index >= requiredLevel.index;
  }

  AuditConfigurationEntity copyWith({
    AuditLogLevel? level,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AuditConfigurationEntity(
      level: level ?? this.level,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  List<Object?> get props => [level, updatedAt, updatedBy];
}
