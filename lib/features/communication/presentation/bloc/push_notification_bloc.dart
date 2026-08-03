import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_push_topics.dart';
import '../../domain/usecases/send_push_notification.dart';
import 'push_notification_event.dart';
import 'push_notification_state.dart';

class PushNotificationBloc
    extends Bloc<PushNotificationEvent, PushNotificationState> {
  PushNotificationBloc({
    required this._sendNotification,
    required this._subscribeTopic,
    required this._unsubscribeTopic,
  }) : super(const PushNotificationReady()) {
    on<SendPushNotificationRequested>(_send);
    on<SubscribePushTopicRequested>(_subscribe);
    on<UnsubscribePushTopicRequested>(_unsubscribe);
  }

  final SendPushNotification _sendNotification;
  final SubscribeCommunicationTopic _subscribeTopic;
  final UnsubscribeCommunicationTopic _unsubscribeTopic;

  Future<void> _send(
    SendPushNotificationRequested event,
    Emitter<PushNotificationState> emit,
  ) async {
    emit(const PushNotificationProcessing());
    try {
      await _sendNotification(event.request);
      emit(const PushNotificationSuccess('Push notification request sent.'));
    } catch (error) {
      emit(PushNotificationFailure(_message(error)));
    }
  }

  Future<void> _subscribe(
    SubscribePushTopicRequested event,
    Emitter<PushNotificationState> emit,
  ) async {
    emit(const PushNotificationProcessing());
    try {
      await _subscribeTopic(event.topic);
      emit(PushNotificationSuccess('Subscribed to ${event.topic}.'));
    } catch (error) {
      emit(PushNotificationFailure(_message(error)));
    }
  }

  Future<void> _unsubscribe(
    UnsubscribePushTopicRequested event,
    Emitter<PushNotificationState> emit,
  ) async {
    emit(const PushNotificationProcessing());
    try {
      await _unsubscribeTopic(event.topic);
      emit(PushNotificationSuccess('Unsubscribed from ${event.topic}.'));
    } catch (error) {
      emit(PushNotificationFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
