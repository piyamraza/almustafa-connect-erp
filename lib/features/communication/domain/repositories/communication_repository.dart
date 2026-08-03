import '../entities/communication_message_entity.dart';

abstract class CommunicationRepository {
  Future<List<CommunicationMessageEntity>> getMessages();
  Future<void> saveMessage(CommunicationMessageEntity message);
  Future<void> deleteMessage(String messageId);
}
