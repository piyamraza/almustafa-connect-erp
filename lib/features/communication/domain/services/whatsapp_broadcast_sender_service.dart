import '../entities/whatsapp_broadcast_entity.dart';

abstract class WhatsAppBroadcastSenderService {
  Future<void> sendBroadcast(WhatsAppBroadcastEntity broadcast);
}
