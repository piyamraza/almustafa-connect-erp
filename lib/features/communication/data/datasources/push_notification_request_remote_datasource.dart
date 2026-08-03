import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/push_notification_request_entity.dart';
import '../models/push_notification_request_model.dart';

abstract class PushNotificationRequestRemoteDataSource {
  Future<void> saveRequest(PushNotificationRequestEntity request);
  Future<List<PushNotificationRequestEntity>> getRequests();
}

class PushNotificationRequestRemoteDataSourceImpl
    implements PushNotificationRequestRemoteDataSource {
  PushNotificationRequestRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<void> saveRequest(PushNotificationRequestEntity request) {
    return _service
        .collection(FirestorePaths.pushNotificationRequests)
        .doc(request.id)
        .set(PushNotificationRequestModel.fromEntity(request).toMap());
  }

  @override
  Future<List<PushNotificationRequestEntity>> getRequests() async {
    final snapshot = await _service
        .collection(FirestorePaths.pushNotificationRequests)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => PushNotificationRequestModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();

    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }
}
