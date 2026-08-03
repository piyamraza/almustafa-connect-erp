import '../entities/communication_message_entity.dart';
import '../repositories/communication_repository.dart';

class SaveCommunicationMessage {
  const SaveCommunicationMessage(this._repository);

  final CommunicationRepository _repository;

  Future<void> call(CommunicationMessageEntity message) {
    if (message.title.trim().isEmpty) {
      throw ArgumentError('Message title is required.');
    }
    if (message.body.trim().isEmpty) {
      throw ArgumentError('Message body is required.');
    }
    if (message.channels.isEmpty) {
      throw ArgumentError('Select at least one channel.');
    }
    return _repository.saveMessage(message);
  }
}
