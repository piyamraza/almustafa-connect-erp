import '../entities/whatsapp_message_request_entity.dart';

abstract class WhatsAppSenderService {
  Future<void> send(WhatsAppMessageRequestEntity request);
}
