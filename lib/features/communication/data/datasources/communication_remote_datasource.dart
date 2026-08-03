import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/communication_message_entity.dart';
import '../models/communication_message_model.dart';

abstract class CommunicationRemoteDataSource {
  Future<List<CommunicationMessageEntity>> getMessages();
  Future<void> saveMessage(CommunicationMessageEntity message);
  Future<void> deleteMessage(String messageId);
}

class CommunicationRemoteDataSourceImpl
    implements CommunicationRemoteDataSource {
  CommunicationRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<CommunicationMessageEntity>> getMessages() async {
    final snapshot = await _service
        .collection(FirestorePaths.communicationMessages)
        .get();

    final values = snapshot.docs
        .map(
          (doc) =>
              CommunicationMessageModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();

    values.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return values;
  }

  @override
  Future<void> saveMessage(CommunicationMessageEntity message) {
    final model = CommunicationMessageModel(
      id: message.id,
      title: message.title,
      body: message.body,
      channels: message.channels,
      audienceType: message.audienceType,
      targetIds: message.targetIds,
      status: message.status,
      isPinned: message.isPinned,
      createdBy: message.createdBy,
      createdAt: message.createdAt,
      updatedAt: message.updatedAt,
      scheduledAt: message.scheduledAt,
      publishedAt: message.publishedAt,
      expiresAt: message.expiresAt,
      attachmentUrl: message.attachmentUrl,
    );

    return _service
        .collection(FirestorePaths.communicationMessages)
        .doc(message.id)
        .set(model.toMap());
  }

  @override
  Future<void> deleteMessage(String messageId) {
    return _service
        .collection(FirestorePaths.communicationMessages)
        .doc(messageId)
        .delete();
  }
}
