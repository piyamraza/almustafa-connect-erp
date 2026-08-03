import '../entities/whatsapp_broadcast_entity.dart';

abstract class WhatsAppBroadcastRepository {
  Future<List<WhatsAppBroadcastEntity>> getBroadcasts();
  Future<void> saveBroadcast(WhatsAppBroadcastEntity broadcast);
}
