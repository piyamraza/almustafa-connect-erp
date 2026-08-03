import '../repositories/communication_repository.dart';

class DeleteCommunicationMessage {
  const DeleteCommunicationMessage(this._repository);

  final CommunicationRepository _repository;

  Future<void> call(String messageId) {
    if (messageId.trim().isEmpty) {
      throw ArgumentError('Message ID is required.');
    }
    return _repository.deleteMessage(messageId);
  }
}
