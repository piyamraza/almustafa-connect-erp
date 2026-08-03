import '../../domain/entities/communication_message_entity.dart';
import '../../domain/repositories/communication_repository.dart';
import '../datasources/communication_remote_datasource.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  CommunicationRepositoryImpl(this._source);

  final CommunicationRemoteDataSource _source;

  @override
  Future<List<CommunicationMessageEntity>> getMessages() {
    return _source.getMessages();
  }

  @override
  Future<void> saveMessage(CommunicationMessageEntity message) {
    return _source.saveMessage(message);
  }

  @override
  Future<void> deleteMessage(String messageId) {
    return _source.deleteMessage(messageId);
  }
}
