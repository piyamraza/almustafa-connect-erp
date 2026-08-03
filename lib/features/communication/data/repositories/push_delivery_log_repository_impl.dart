import '../../domain/entities/push_delivery_log_entity.dart';
import '../../domain/repositories/push_delivery_log_repository.dart';
import '../datasources/push_delivery_log_remote_datasource.dart';

class PushDeliveryLogRepositoryImpl implements PushDeliveryLogRepository {
  const PushDeliveryLogRepositoryImpl(this._source);

  final PushDeliveryLogRemoteDataSource _source;

  @override
  Future<List<PushDeliveryLogEntity>> getLogs() {
    return _source.getLogs();
  }

  @override
  Future<void> saveLog(PushDeliveryLogEntity log) {
    return _source.saveLog(log);
  }
}
