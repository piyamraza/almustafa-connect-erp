import '../entities/communication_broadcast_entity.dart';

abstract class CommunicationBroadcastRepository {
  Future<List<CommunicationBroadcastEntity>> getBroadcasts();

  Future<void> saveBroadcast(CommunicationBroadcastEntity broadcast);

  Future<bool> existsByDeduplicationKey(String key);
}
