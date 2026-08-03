import '../../domain/entities/push_device_token_entity.dart';
import '../../domain/repositories/push_device_token_repository.dart';
import '../datasources/push_device_token_remote_datasource.dart';

class PushDeviceTokenRepositoryImpl implements PushDeviceTokenRepository {
  PushDeviceTokenRepositoryImpl(this._source);
  final PushDeviceTokenRemoteDataSource _source;
  @override
  Future<void> saveToken(PushDeviceTokenEntity token) =>
      _source.saveToken(token);
  @override
  Future<List<PushDeviceTokenEntity>> getUserTokens(String userId) =>
      _source.getUserTokens(userId);
}
