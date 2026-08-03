import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/push_delivery_log_entity.dart';
import '../models/push_delivery_log_model.dart';

abstract class PushDeliveryLogRemoteDataSource {
  Future<List<PushDeliveryLogEntity>> getLogs();
  Future<void> saveLog(PushDeliveryLogEntity log);
}

class PushDeliveryLogRemoteDataSourceImpl
    implements PushDeliveryLogRemoteDataSource {
  PushDeliveryLogRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<PushDeliveryLogEntity>> getLogs() async {
    final snapshot = await _service
        .collection(FirestorePaths.communicationDeliveryLogs)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => PushDeliveryLogModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();

    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  @override
  Future<void> saveLog(PushDeliveryLogEntity log) {
    return _service
        .collection(FirestorePaths.communicationDeliveryLogs)
        .doc(log.id)
        .set(PushDeliveryLogModel.fromEntity(log).toMap());
  }
}
