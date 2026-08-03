import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/push_device_token_entity.dart';
import '../models/push_device_token_model.dart';

abstract class PushDeviceTokenRemoteDataSource {
  Future<void> saveToken(PushDeviceTokenEntity token);
  Future<List<PushDeviceTokenEntity>> getUserTokens(String userId);
}

class PushDeviceTokenRemoteDataSourceImpl
    implements PushDeviceTokenRemoteDataSource {
  PushDeviceTokenRemoteDataSourceImpl(this._service);
  final FirebaseFirestoreService _service;
  @override
  Future<void> saveToken(PushDeviceTokenEntity token) => _service
      .collection(FirestorePaths.pushDeviceTokens)
      .doc(token.id)
      .set(PushDeviceTokenModel.fromEntity(token).toMap());
  @override
  Future<List<PushDeviceTokenEntity>> getUserTokens(String userId) async {
    final s = await _service
        .collection(FirestorePaths.pushDeviceTokens)
        .where('userId', isEqualTo: userId)
        .get();
    return s.docs
        .map((d) => PushDeviceTokenModel.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }
}
