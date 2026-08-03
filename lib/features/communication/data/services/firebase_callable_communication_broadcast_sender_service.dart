import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/communication_broadcast_entity.dart';
import '../../domain/services/communication_broadcast_sender_service.dart';

class FirebaseCallableCommunicationBroadcastSenderService
    implements CommunicationBroadcastSenderService {
  const FirebaseCallableCommunicationBroadcastSenderService(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<void> send(CommunicationBroadcastEntity broadcast) async {
    final callable = _functions.httpsCallable('sendCommunicationBroadcast');

    await callable.call<void>({
      'broadcastId': broadcast.id,
      'title': broadcast.title,
      'body': broadcast.body,
      'channels': broadcast.channels.map((item) => item.name).toList(),
      'audienceType': broadcast.audienceType.name,
      'targetIds': broadcast.targetIds,
      'attachmentUrl': broadcast.attachmentUrl,
      'scheduledAt': broadcast.scheduledAt?.toIso8601String(),
      'deduplicationKey': broadcast.deduplicationKey,
    });
  }
}
