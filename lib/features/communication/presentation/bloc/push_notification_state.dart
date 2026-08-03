import 'package:equatable/equatable.dart';

sealed class PushNotificationState extends Equatable {
  const PushNotificationState();

  @override
  List<Object?> get props => const [];
}

class PushNotificationReady extends PushNotificationState {
  const PushNotificationReady();
}

class PushNotificationProcessing extends PushNotificationState {
  const PushNotificationProcessing();
}

class PushNotificationSuccess extends PushNotificationState {
  const PushNotificationSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class PushNotificationFailure extends PushNotificationState {
  const PushNotificationFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
