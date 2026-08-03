import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/push_device_token_entity.dart';
import '../../domain/services/push_notification_service.dart';

class FirebasePushNotificationService implements PushNotificationService {
  FirebasePushNotificationService(this._messaging);
  final FirebaseMessaging _messaging;

  @override
  Future<bool> requestPermission() async {
    final s = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();
  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;
  @override
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);
  @override
  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);
  @override
  PushDevicePlatform get currentPlatform {
    if (kIsWeb) return PushDevicePlatform.web;
    if (Platform.isAndroid) return PushDevicePlatform.android;
    if (Platform.isIOS) return PushDevicePlatform.ios;
    if (Platform.isMacOS) return PushDevicePlatform.macos;
    if (Platform.isWindows) return PushDevicePlatform.windows;
    return PushDevicePlatform.unknown;
  }
}
