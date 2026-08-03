import '../entities/push_notification_request_entity.dart';
import '../repositories/push_notification_request_repository.dart';
import '../services/push_sender_service.dart';

class RetryFailedPush {
  const RetryFailedPush(this._repository, this._sender);

  final PushNotificationRequestRepository _repository;
  final PushSenderService _sender;

  Future<void> call(PushNotificationRequestEntity request) async {
    final retry = PushNotificationRequestEntity(
      id: request.id,
      title: request.title,
      body: request.body,
      targetType: request.targetType,
      targetValue: request.targetValue,
      data: request.data,
      status: PushRequestStatus.pending,
      createdBy: request.createdBy,
      createdAt: request.createdAt,
      updatedAt: DateTime.now(),
    );

    await _repository.saveRequest(retry);
    await _sender.send(retry);
  }
}
