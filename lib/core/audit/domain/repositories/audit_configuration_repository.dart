import '../entities/audit_configuration_entity.dart';

abstract class AuditConfigurationRepository {
  Future<AuditConfigurationEntity> getConfiguration();

  Stream<AuditConfigurationEntity> watchConfiguration();

  Future<void> saveConfiguration(AuditConfigurationEntity configuration);
}
