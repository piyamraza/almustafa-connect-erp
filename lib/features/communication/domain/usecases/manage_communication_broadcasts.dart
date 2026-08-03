import '../entities/communication_broadcast_entity.dart';
import '../entities/communication_message_entity.dart';
import '../repositories/communication_broadcast_repository.dart';
import '../services/communication_broadcast_sender_service.dart';

class GetCommunicationBroadcasts {
  const GetCommunicationBroadcasts(this._repository);

  final CommunicationBroadcastRepository _repository;

  Future<List<CommunicationBroadcastEntity>> call() {
    return _repository.getBroadcasts();
  }
}

class QueueCommunicationBroadcast {
  const QueueCommunicationBroadcast(this._repository, this._sender);

  final CommunicationBroadcastRepository _repository;
  final CommunicationBroadcastSenderService _sender;

  Future<void> call(CommunicationBroadcastEntity broadcast) async {
    if (broadcast.title.trim().isEmpty) {
      throw ArgumentError('Broadcast title is required.');
    }

    if (broadcast.body.trim().isEmpty) {
      throw ArgumentError('Broadcast message is required.');
    }

    if (broadcast.channels.isEmpty) {
      throw ArgumentError('Select at least one channel.');
    }

    if ((broadcast.audienceType == CommunicationAudienceType.classSection ||
            broadcast.audienceType ==
                CommunicationAudienceType.selectedUsers) &&
        broadcast.targetIds.isEmpty) {
      throw ArgumentError('Target IDs are required for the selected audience.');
    }

    final duplicate = await _repository.existsByDeduplicationKey(
      broadcast.deduplicationKey,
    );

    if (duplicate) {
      throw StateError('A matching broadcast already exists.');
    }

    await _repository.saveBroadcast(broadcast);

    final scheduledForFuture =
        broadcast.scheduledAt?.isAfter(DateTime.now()) ?? false;

    if (!scheduledForFuture) {
      await _sender.send(broadcast);
    }
  }
}

class RetryCommunicationBroadcast {
  const RetryCommunicationBroadcast(this._repository, this._sender);

  final CommunicationBroadcastRepository _repository;
  final CommunicationBroadcastSenderService _sender;

  Future<void> call(CommunicationBroadcastEntity broadcast) async {
    final retry = CommunicationBroadcastEntity(
      id: broadcast.id,
      title: broadcast.title,
      body: broadcast.body,
      channels: broadcast.channels,
      audienceType: broadcast.audienceType,
      targetIds: broadcast.targetIds,
      status: CommunicationBroadcastStatus.queued,
      createdBy: broadcast.createdBy,
      createdAt: broadcast.createdAt,
      updatedAt: DateTime.now(),
      scheduledAt: broadcast.scheduledAt,
      attachmentUrl: broadcast.attachmentUrl,
      totalRecipients: broadcast.totalRecipients,
      sentCount: broadcast.sentCount,
      deliveredCount: broadcast.deliveredCount,
      readCount: broadcast.readCount,
      failedCount: broadcast.failedCount,
      deduplicationKey: broadcast.deduplicationKey,
    );

    await _repository.saveBroadcast(retry);
    await _sender.send(retry);
  }
}
