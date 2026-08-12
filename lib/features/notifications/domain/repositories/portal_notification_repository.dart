import '../entities/portal_notification_entity.dart';

abstract class PortalNotificationRepository {
  Future<List<PortalNotificationEntity>> getNotifications({
    required PortalRecipientType recipientType,
    required String recipientId,
    bool? isRead,
  });

  Future<void> create({
    required PortalRecipientType recipientType,
    required String recipientId,
    required String title,
    required String message,
    required PortalNotificationType type,
    String referenceId = '',
    String studentId = '',
  });

  Future<void> markRead(String id);
  Future<void> markAllRead({
    required PortalRecipientType recipientType,
    required String recipientId,
  });
  String generateId();
}
