import '../entities/push_delivery_log_entity.dart';

abstract class PushDeliveryLogRepository {
  Future<List<PushDeliveryLogEntity>> getLogs();
  Future<void> saveLog(PushDeliveryLogEntity log);
}
