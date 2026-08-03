import '../entities/push_device_token_entity.dart';

abstract class PushDeviceTokenRepository {
  Future<void> saveToken(PushDeviceTokenEntity token);
  Future<List<PushDeviceTokenEntity>> getUserTokens(String userId);
}
