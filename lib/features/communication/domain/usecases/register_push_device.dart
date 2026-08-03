import '../entities/push_device_token_entity.dart';
import '../repositories/push_device_token_repository.dart';
import '../services/push_notification_service.dart';

class RegisterPushDevice {
  const RegisterPushDevice(this._service, this._repository);
  final PushNotificationService _service;
  final PushDeviceTokenRepository _repository;

  Future<PushDeviceTokenEntity> call({
    required String userId,
    String deviceName = '',
  }) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('Authenticated user is required.');
    }
    if (!await _service.requestPermission()) {
      throw StateError('Notification permission was not granted.');
    }
    final token = await _service.getToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('FCM token could not be generated.');
    }
    final now = DateTime.now();
    final safe = token.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final entity = PushDeviceTokenEntity(
      id: '${userId}_$safe',
      userId: userId,
      token: token,
      platform: _service.currentPlatform,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      deviceName: deviceName,
    );
    await _repository.saveToken(entity);
    return entity;
  }
}
