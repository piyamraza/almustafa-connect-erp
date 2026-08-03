import '../../domain/entities/whatsapp_broadcast_entity.dart';
import '../../domain/repositories/whatsapp_broadcast_repository.dart';
import '../datasources/whatsapp_broadcast_remote_datasource.dart';

class WhatsAppBroadcastRepositoryImpl implements WhatsAppBroadcastRepository {
  const WhatsAppBroadcastRepositoryImpl(this._source);

  final WhatsAppBroadcastRemoteDataSource _source;

  @override
  Future<List<WhatsAppBroadcastEntity>> getBroadcasts() {
    return _source.getBroadcasts();
  }

  @override
  Future<void> saveBroadcast(WhatsAppBroadcastEntity broadcast) {
    return _source.saveBroadcast(broadcast);
  }
}
