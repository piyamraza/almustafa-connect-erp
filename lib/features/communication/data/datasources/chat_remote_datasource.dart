import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';
import '../models/chat_message_model.dart';
import '../models/chat_thread_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatThreadEntity>> getThreadsForUser(String userId);

  Future<List<ChatMessageEntity>> getMessages(String threadId);

  Future<void> saveThread(ChatThreadEntity thread);

  Future<void> saveMessage(ChatMessageEntity message);

  Future<void> markThreadRead({
    required String threadId,
    required String userId,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  const ChatRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<ChatThreadEntity>> getThreadsForUser(String userId) async {
    final snapshot = await _service
        .collection(FirestorePaths.communicationThreads)
        .where('participantIds', arrayContains: userId)
        .get();

    final values = snapshot.docs
        .map((doc) => ChatThreadModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    values.sort((a, b) {
      final aDate = a.lastMessageAt ?? a.updatedAt;
      final bDate = b.lastMessageAt ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });

    return values;
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(String threadId) async {
    final snapshot = await _service
        .collection(FirestorePaths.chatMessages)
        .where('threadId', isEqualTo: threadId)
        .get();

    final values = snapshot.docs
        .map((doc) => ChatMessageModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    values.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return values;
  }

  @override
  Future<void> saveThread(ChatThreadEntity thread) {
    return _service
        .collection(FirestorePaths.communicationThreads)
        .doc(thread.id)
        .set(ChatThreadModel.fromEntity(thread).toMap());
  }

  @override
  Future<void> saveMessage(ChatMessageEntity message) async {
    await _service
        .collection(FirestorePaths.chatMessages)
        .doc(message.id)
        .set(ChatMessageModel.fromEntity(message).toMap());

    await _service
        .collection(FirestorePaths.communicationThreads)
        .doc(message.threadId)
        .update({
          'lastMessage': message.text.isNotEmpty
              ? message.text
              : message.attachmentName,
          'lastMessageAt': message.createdAt.toIso8601String(),
          'updatedAt': message.createdAt.toIso8601String(),
        });
  }

  @override
  Future<void> markThreadRead({
    required String threadId,
    required String userId,
  }) async {
    final messages = await getMessages(threadId);

    for (final message in messages) {
      if (message.senderId == userId || message.readBy.contains(userId)) {
        continue;
      }

      await _service
          .collection(FirestorePaths.chatMessages)
          .doc(message.id)
          .update({
            'readBy': [...message.readBy, userId],
          });
    }
  }
}
