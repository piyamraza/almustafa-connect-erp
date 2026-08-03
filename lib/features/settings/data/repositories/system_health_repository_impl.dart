import '../../domain/entities/system_health_entity.dart';
import '../../domain/repositories/system_health_repository.dart';
import '../datasources/system_health_remote_datasource.dart';

class SystemHealthRepositoryImpl implements SystemHealthRepository {
  const SystemHealthRepositoryImpl(this._source);

  final SystemHealthRemoteDataSource _source;

  @override
  Future<SystemHealthEntity> checkHealth() {
    return _source.checkHealth();
  }

  @override
  Future<void> writeHealthLog(SystemHealthEntity health) {
    return _source.writeHealthLog(health);
  }
}
