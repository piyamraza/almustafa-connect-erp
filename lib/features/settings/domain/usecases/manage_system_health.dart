import '../entities/system_health_entity.dart';
import '../repositories/system_health_repository.dart';

class CheckSystemHealth {
  const CheckSystemHealth(this._repository);

  final SystemHealthRepository _repository;

  Future<SystemHealthEntity> call() async {
    final health = await _repository.checkHealth();
    await _repository.writeHealthLog(health);
    return health;
  }
}
