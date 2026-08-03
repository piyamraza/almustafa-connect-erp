import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/whatsapp_broadcast_entity.dart';
import '../models/whatsapp_broadcast_model.dart';

abstract class WhatsAppBroadcastRemoteDataSource {
  Future<List<WhatsAppBroadcastEntity>> getBroadcasts();
  Future<void> saveBroadcast(WhatsAppBroadcastEntity broadcast);
}

class WhatsAppBroadcastRemoteDataSourceImpl
    implements WhatsAppBroadcastRemoteDataSource {
  const WhatsAppBroadcastRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<WhatsAppBroadcastEntity>> getBroadcasts() async {
    final snapshot = await _service
        .collection(FirestorePaths.whatsappBroadcasts)
        .get();

    final values = snapshot.docs
        .map(
          (doc) =>
              WhatsAppBroadcastModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();

    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  @override
  Future<void> saveBroadcast(WhatsAppBroadcastEntity broadcast) {
    return _service
        .collection(FirestorePaths.whatsappBroadcasts)
        .doc(broadcast.id)
        .set(WhatsAppBroadcastModel.fromEntity(broadcast).toMap());
  }
}
