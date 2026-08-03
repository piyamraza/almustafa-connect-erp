import '../entities/communication_message_entity.dart';
import '../repositories/communication_repository.dart';

class GetCommunicationMessages {
  const GetCommunicationMessages(this._repository);

  final CommunicationRepository _repository;

  Future<List<CommunicationMessageEntity>> call() => _repository.getMessages();
}
