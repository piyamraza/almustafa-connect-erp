import '../entities/push_device_token_entity.dart';

abstract class PushNotificationService {
  Future<bool> requestPermission();
  Future<String?> getToken();
  Stream<String> get tokenRefreshes;
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  PushDevicePlatform get currentPlatform;
}
