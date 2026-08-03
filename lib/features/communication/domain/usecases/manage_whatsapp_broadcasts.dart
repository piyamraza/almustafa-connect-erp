import '../entities/whatsapp_broadcast_entity.dart';
import '../repositories/whatsapp_broadcast_repository.dart';
import '../services/whatsapp_broadcast_sender_service.dart';

class GetWhatsAppBroadcasts {
  const GetWhatsAppBroadcasts(this._repository);

  final WhatsAppBroadcastRepository _repository;

  Future<List<WhatsAppBroadcastEntity>> call() {
    return _repository.getBroadcasts();
  }
}

class QueueWhatsAppBroadcast {
  const QueueWhatsAppBroadcast(this._repository, this._sender);

  final WhatsAppBroadcastRepository _repository;
  final WhatsAppBroadcastSenderService _sender;

  Future<void> call(WhatsAppBroadcastEntity broadcast) async {
    if (broadcast.title.trim().isEmpty) {
      throw ArgumentError('Broadcast title is required.');
    }

    if (broadcast.templateName.trim().isEmpty) {
      throw ArgumentError('Approved WhatsApp template is required.');
    }

    if (broadcast.audience == WhatsAppBroadcastAudience.selectedRecipients &&
        broadcast.targetIds.isEmpty) {
      throw ArgumentError('Select at least one recipient.');
    }

    if (broadcast.audience == WhatsAppBroadcastAudience.classSection &&
        broadcast.targetIds.isEmpty) {
      throw ArgumentError('Select at least one class or section.');
    }

    await _repository.saveBroadcast(broadcast);

    if (broadcast.scheduledAt == null ||
        !broadcast.scheduledAt!.isAfter(DateTime.now())) {
      await _sender.sendBroadcast(broadcast);
    }
  }
}

class RetryWhatsAppBroadcast {
  const RetryWhatsAppBroadcast(this._repository, this._sender);

  final WhatsAppBroadcastRepository _repository;
  final WhatsAppBroadcastSenderService _sender;

  Future<void> call(WhatsAppBroadcastEntity broadcast) async {
    final retry = WhatsAppBroadcastEntity(
      id: broadcast.id,
      title: broadcast.title,
      templateName: broadcast.templateName,
      languageCode: broadcast.languageCode,
      audience: broadcast.audience,
      targetIds: broadcast.targetIds,
      parameters: broadcast.parameters,
      automationType: broadcast.automationType,
      status: WhatsAppBroadcastStatus.queued,
      createdBy: broadcast.createdBy,
      createdAt: broadcast.createdAt,
      updatedAt: DateTime.now(),
      attachmentUrl: broadcast.attachmentUrl,
      scheduledAt: broadcast.scheduledAt,
      totalRecipients: broadcast.totalRecipients,
      successCount: broadcast.successCount,
      failureCount: broadcast.failureCount,
    );

    await _repository.saveBroadcast(retry);
    await _sender.sendBroadcast(retry);
  }
}
