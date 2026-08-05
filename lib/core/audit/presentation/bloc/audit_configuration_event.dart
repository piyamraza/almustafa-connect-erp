import 'package:equatable/equatable.dart';

import '../../domain/entities/audit_configuration_entity.dart';

sealed class AuditConfigurationEvent extends Equatable {
  const AuditConfigurationEvent();

  @override
  List<Object?> get props => [];
}

final class LoadAuditConfiguration extends AuditConfigurationEvent {
  const LoadAuditConfiguration();
}

final class ChangeAuditLogLevel extends AuditConfigurationEvent {
  const ChangeAuditLogLevel(this.level);

  final AuditLogLevel level;

  @override
  List<Object?> get props => [level];
}
final class DeleteAllAuditLogs extends AuditConfigurationEvent {
  const DeleteAllAuditLogs();
}
