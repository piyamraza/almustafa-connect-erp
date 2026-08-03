import '../entities/communication_broadcast_entity.dart';

abstract class CommunicationBroadcastSenderService {
  Future<void> send(CommunicationBroadcastEntity broadcast);
}
