import '../services/push_topic_service.dart';

class SubscribeCommunicationTopic {
  const SubscribeCommunicationTopic(this._service);

  final PushTopicService _service;

  Future<void> call(String topic) => _service.subscribe(topic);
}

class UnsubscribeCommunicationTopic {
  const UnsubscribeCommunicationTopic(this._service);

  final PushTopicService _service;

  Future<void> call(String topic) => _service.unsubscribe(topic);
}
