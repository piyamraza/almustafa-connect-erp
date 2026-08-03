import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/whatsapp_message_request_entity.dart';
import '../../domain/services/whatsapp_sender_service.dart';

class FirebaseCallableWhatsAppSenderService implements WhatsAppSenderService {
  const FirebaseCallableWhatsAppSenderService(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<void> send(WhatsAppMessageRequestEntity request) async {
    final callable = _functions.httpsCallable('sendCommunicationWhatsApp');

    await callable.call<void>({
      'requestId': request.id,
      'recipientPhone': request.recipientPhone,
      'templateName': request.templateName,
      'languageCode': request.languageCode,
      'parameters': request.parameters,
      'attachmentUrl': request.attachmentUrl,
    });
  }
}
