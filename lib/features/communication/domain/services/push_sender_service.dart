import '../entities/push_notification_request_entity.dart';

abstract class PushSenderService {
  Future<void> send(PushNotificationRequestEntity request);
}
