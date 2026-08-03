import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/whatsapp_broadcast_entity.dart';
import '../../domain/services/whatsapp_broadcast_sender_service.dart';

class FirebaseCallableWhatsAppBroadcastSenderService
    implements WhatsAppBroadcastSenderService {
  const FirebaseCallableWhatsAppBroadcastSenderService(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<void> sendBroadcast(WhatsAppBroadcastEntity broadcast) async {
    final callable = _functions.httpsCallable(
      'sendCommunicationWhatsAppBroadcast',
    );

    await callable.call<void>({
      'broadcastId': broadcast.id,
      'title': broadcast.title,
      'templateName': broadcast.templateName,
      'languageCode': broadcast.languageCode,
      'audience': broadcast.audience.name,
      'targetIds': broadcast.targetIds,
      'parameters': broadcast.parameters,
      'automationType': broadcast.automationType.name,
      'attachmentUrl': broadcast.attachmentUrl,
      'scheduledAt': broadcast.scheduledAt?.toIso8601String(),
    });
  }
}
