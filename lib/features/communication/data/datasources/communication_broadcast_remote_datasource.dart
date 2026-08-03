import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/communication_broadcast_entity.dart';
import '../models/communication_broadcast_model.dart';

abstract class CommunicationBroadcastRemoteDataSource {
  Future<List<CommunicationBroadcastEntity>> getBroadcasts();

  Future<void> saveBroadcast(CommunicationBroadcastEntity broadcast);

  Future<bool> existsByDeduplicationKey(String key);
}

class CommunicationBroadcastRemoteDataSourceImpl
    implements CommunicationBroadcastRemoteDataSource {
  const CommunicationBroadcastRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<CommunicationBroadcastEntity>> getBroadcasts() async {
    final snapshot = await _service
        .collection(FirestorePaths.communicationBroadcasts)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => CommunicationBroadcastModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();

    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  @override
  Future<void> saveBroadcast(CommunicationBroadcastEntity broadcast) {
    return _service
        .collection(FirestorePaths.communicationBroadcasts)
        .doc(broadcast.id)
        .set(CommunicationBroadcastModel.fromEntity(broadcast).toMap());
  }

  @override
  Future<bool> existsByDeduplicationKey(String key) async {
    if (key.trim().isEmpty) return false;

    final snapshot = await _service
        .collection(FirestorePaths.communicationBroadcasts)
        .where('deduplicationKey', isEqualTo: key)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
