import '../../domain/entities/audit_configuration_entity.dart';
import '../../domain/repositories/audit_configuration_repository.dart';
import '../datasources/audit_configuration_remote_datasource.dart';

class AuditConfigurationRepositoryImpl implements AuditConfigurationRepository {
  AuditConfigurationRepositoryImpl(this._remoteDataSource);

  final AuditConfigurationRemoteDataSource _remoteDataSource;

  @override
  Future<AuditConfigurationEntity> getConfiguration() {
    return _remoteDataSource.getConfiguration();
  }

  @override
  Stream<AuditConfigurationEntity> watchConfiguration() {
    return _remoteDataSource.watchConfiguration();
  }

  @override
  Future<void> saveConfiguration(AuditConfigurationEntity configuration) {
    return _remoteDataSource.saveConfiguration(configuration);
  }
}
