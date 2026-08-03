import 'package:equatable/equatable.dart';

import '../../domain/entities/push_notification_request_entity.dart';

sealed class PushHistoryEvent extends Equatable {
  const PushHistoryEvent();

  @override
  List<Object?> get props => const [];
}

class LoadPushHistory extends PushHistoryEvent {
  const LoadPushHistory();
}

class RetryPushRequested extends PushHistoryEvent {
  const RetryPushRequested(this.request);

  final PushNotificationRequestEntity request;

  @override
  List<Object?> get props => [request];
}
