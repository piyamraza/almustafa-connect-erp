import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._source);

  final ChatRemoteDataSource _source;

  @override
  Future<List<ChatThreadEntity>> getThreadsForUser(String userId) {
    return _source.getThreadsForUser(userId);
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(String threadId) {
    return _source.getMessages(threadId);
  }

  @override
  Future<void> saveThread(ChatThreadEntity thread) {
    return _source.saveThread(thread);
  }

  @override
  Future<void> saveMessage(ChatMessageEntity message) {
    return _source.saveMessage(message);
  }

  @override
  Future<void> markThreadRead({
    required String threadId,
    required String userId,
  }) {
    return _source.markThreadRead(threadId: threadId, userId: userId);
  }

  @override
  Future<void> removeThreadForUser({
    required String threadId,
    required String userId,
  }) {
    return _source.removeThreadForUser(threadId: threadId, userId: userId);
  }
}
