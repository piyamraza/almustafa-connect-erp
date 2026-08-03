import '../../domain/entities/push_notification_request_entity.dart';
import '../../domain/repositories/push_notification_request_repository.dart';
import '../datasources/push_notification_request_remote_datasource.dart';

class PushNotificationRequestRepositoryImpl
    implements PushNotificationRequestRepository {
  const PushNotificationRequestRepositoryImpl(this._source);

  final PushNotificationRequestRemoteDataSource _source;

  @override
  Future<void> saveRequest(PushNotificationRequestEntity request) {
    return _source.saveRequest(request);
  }

  @override
  Future<List<PushNotificationRequestEntity>> getRequests() {
    return _source.getRequests();
  }
}
