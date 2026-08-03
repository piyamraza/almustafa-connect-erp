import '../entities/system_health_entity.dart';

abstract class SystemHealthRepository {
  Future<SystemHealthEntity> checkHealth();
  Future<void> writeHealthLog(SystemHealthEntity health);
}
