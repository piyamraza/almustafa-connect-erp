import 'package:equatable/equatable.dart';

import '../../domain/entities/push_notification_request_entity.dart';

sealed class PushNotificationEvent extends Equatable {
  const PushNotificationEvent();

  @override
  List<Object?> get props => const [];
}

class SendPushNotificationRequested extends PushNotificationEvent {
  const SendPushNotificationRequested(this.request);

  final PushNotificationRequestEntity request;

  @override
  List<Object?> get props => [request];
}

class SubscribePushTopicRequested extends PushNotificationEvent {
  const SubscribePushTopicRequested(this.topic);

  final String topic;

  @override
  List<Object?> get props => [topic];
}

class UnsubscribePushTopicRequested extends PushNotificationEvent {
  const UnsubscribePushTopicRequested(this.topic);

  final String topic;

  @override
  List<Object?> get props => [topic];
}
