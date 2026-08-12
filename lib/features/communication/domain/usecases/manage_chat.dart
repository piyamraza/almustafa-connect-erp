import '../entities/chat_message_entity.dart';
import '../entities/chat_thread_entity.dart';
import '../repositories/chat_repository.dart';

class GetChatThreads {
  const GetChatThreads(this._repository);

  final ChatRepository _repository;

  Future<List<ChatThreadEntity>> call(String userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('Authenticated user is required.');
    }
    return _repository.getThreadsForUser(userId);
  }
}

class GetChatMessages {
  const GetChatMessages(this._repository);

  final ChatRepository _repository;

  Future<List<ChatMessageEntity>> call(String threadId) {
    if (threadId.trim().isEmpty) {
      throw ArgumentError('Chat thread is required.');
    }
    return _repository.getMessages(threadId);
  }
}

class CreateChatThread {
  const CreateChatThread(this._repository);

  final ChatRepository _repository;

  Future<void> call(ChatThreadEntity thread) {
    if (thread.participantIds.length < 2) {
      throw ArgumentError('At least two participants are required.');
    }
    return _repository.saveThread(thread);
  }
}

class SendChatMessage {
  const SendChatMessage(this._repository);

  final ChatRepository _repository;

  Future<void> call(ChatMessageEntity message) {
    final hasText = message.text.trim().isNotEmpty;
    final hasAttachment = message.attachmentUrl.trim().isNotEmpty;

    if (!hasText && !hasAttachment) {
      throw ArgumentError('Message text or attachment is required.');
    }

    return _repository.saveMessage(message);
  }
}

class MarkChatThreadRead {
  const MarkChatThreadRead(this._repository);

  final ChatRepository _repository;

  Future<void> call({required String threadId, required String userId}) {
    return _repository.markThreadRead(threadId: threadId, userId: userId);
  }
}

class RemoveChatThreadForUser {
  const RemoveChatThreadForUser(this._repository);

  final ChatRepository _repository;

  Future<void> call({required String threadId, required String userId}) {
    if (threadId.trim().isEmpty || userId.trim().isEmpty) {
      throw ArgumentError('Chat thread and authenticated user are required.');
    }
    return _repository.removeThreadForUser(threadId: threadId, userId: userId);
  }
}
