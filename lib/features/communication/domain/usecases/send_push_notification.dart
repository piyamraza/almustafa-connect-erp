import '../entities/push_notification_request_entity.dart';
import '../repositories/push_notification_request_repository.dart';
import '../services/push_sender_service.dart';

class SendPushNotification {
  const SendPushNotification(this._repository, this._sender);

  final PushNotificationRequestRepository _repository;
  final PushSenderService _sender;

  Future<void> call(PushNotificationRequestEntity request) async {
    if (request.title.trim().isEmpty) {
      throw ArgumentError('Notification title is required.');
    }
    if (request.body.trim().isEmpty) {
      throw ArgumentError('Notification body is required.');
    }
    if (request.targetValue.trim().isEmpty) {
      throw ArgumentError('Notification target is required.');
    }

    await _repository.saveRequest(request);

    try {
      await _sender.send(request);
    } catch (error) {
      final failed = PushNotificationRequestEntity(
        id: request.id,
        title: request.title,
        body: request.body,
        targetType: request.targetType,
        targetValue: request.targetValue,
        data: request.data,
        status: PushRequestStatus.failed,
        createdBy: request.createdBy,
        createdAt: request.createdAt,
        updatedAt: DateTime.now(),
        failureReason: error.toString(),
      );
      await _repository.saveRequest(failed);
      rethrow;
    }
  }
}
