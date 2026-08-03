import '../../domain/entities/communication_broadcast_entity.dart';
import '../../domain/repositories/communication_broadcast_repository.dart';
import '../datasources/communication_broadcast_remote_datasource.dart';

class CommunicationBroadcastRepositoryImpl
    implements CommunicationBroadcastRepository {
  const CommunicationBroadcastRepositoryImpl(this._source);

  final CommunicationBroadcastRemoteDataSource _source;

  @override
  Future<List<CommunicationBroadcastEntity>> getBroadcasts() {
    return _source.getBroadcasts();
  }

  @override
  Future<void> saveBroadcast(CommunicationBroadcastEntity broadcast) {
    return _source.saveBroadcast(broadcast);
  }

  @override
  Future<bool> existsByDeduplicationKey(String key) {
    return _source.existsByDeduplicationKey(key);
  }
}
