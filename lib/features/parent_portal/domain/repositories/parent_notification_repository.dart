import '../entities/parent_notification_entity.dart';

abstract class ParentNotificationRepository {
  Future<List<ParentNotificationEntity>> getNotifications({
    required String parentId,
    String? studentId,
    ParentNotificationType? type,
    bool? isRead,
  });

  Future<void> saveNotification(ParentNotificationEntity notification);

  Future<void> markRead(String id);

  Future<void> markAllRead({required String parentId, String? studentId});

  Future<void> deleteNotification(String id);

  String generateId();
}
