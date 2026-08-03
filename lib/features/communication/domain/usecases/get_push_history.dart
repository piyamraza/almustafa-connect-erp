import '../entities/push_delivery_log_entity.dart';
import '../entities/push_notification_request_entity.dart';
import '../repositories/push_delivery_log_repository.dart';
import '../repositories/push_notification_request_repository.dart';

class PushHistoryData {
  const PushHistoryData({required this.requests, required this.logs});

  final List<PushNotificationRequestEntity> requests;
  final List<PushDeliveryLogEntity> logs;
}

class GetPushHistory {
  const GetPushHistory(this._requestRepository, this._logRepository);

  final PushNotificationRequestRepository _requestRepository;
  final PushDeliveryLogRepository _logRepository;

  Future<PushHistoryData> call() async {
    final values = await Future.wait<Object>([
      _requestRepository.getRequests(),
      _logRepository.getLogs(),
    ]);

    return PushHistoryData(
      requests: values[0] as List<PushNotificationRequestEntity>,
      logs: values[1] as List<PushDeliveryLogEntity>,
    );
  }
}
