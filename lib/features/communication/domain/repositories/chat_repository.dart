import '../entities/chat_message_entity.dart';
import '../entities/chat_thread_entity.dart';

abstract class ChatRepository {
  Future<List<ChatThreadEntity>> getThreadsForUser(String userId);

  Future<List<ChatMessageEntity>> getMessages(String threadId);

  Future<void> saveThread(ChatThreadEntity thread);

  Future<void> saveMessage(ChatMessageEntity message);

  Future<void> markThreadRead({
    required String threadId,
    required String userId,
  });

  Future<void> removeThreadForUser({
    required String threadId,
    required String userId,
  });
}
