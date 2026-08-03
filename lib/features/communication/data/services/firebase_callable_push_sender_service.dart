import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/push_notification_request_entity.dart';
import '../../domain/services/push_sender_service.dart';

class FirebaseCallablePushSenderService implements PushSenderService {
  const FirebaseCallablePushSenderService(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<void> send(PushNotificationRequestEntity request) async {
    final callable = _functions.httpsCallable('sendCommunicationPush');

    await callable.call<void>({
      'requestId': request.id,
      'title': request.title,
      'body': request.body,
      'targetType': request.targetType.name,
      'targetValue': request.targetValue,
      'data': request.data,
    });
  }
}
