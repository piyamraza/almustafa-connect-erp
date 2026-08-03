import '../entities/push_notification_request_entity.dart';

abstract class PushNotificationRequestRepository {
  Future<void> saveRequest(PushNotificationRequestEntity request);
  Future<List<PushNotificationRequestEntity>> getRequests();
}
