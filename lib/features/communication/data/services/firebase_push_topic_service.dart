import '../../domain/services/push_notification_service.dart';
import '../../domain/services/push_topic_service.dart';

class FirebasePushTopicService implements PushTopicService {
  const FirebasePushTopicService(this._service);

  final PushNotificationService _service;

  @override
  Future<void> subscribe(String topic) {
    if (topic.trim().isEmpty) {
      throw ArgumentError('Topic is required.');
    }
    return _service.subscribeToTopic(topic.trim());
  }

  @override
  Future<void> unsubscribe(String topic) {
    if (topic.trim().isEmpty) {
      throw ArgumentError('Topic is required.');
    }
    return _service.unsubscribeFromTopic(topic.trim());
  }
}
