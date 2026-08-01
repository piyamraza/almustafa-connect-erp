import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/parent_notification_entity.dart';
import '../../domain/repositories/parent_notification_repository.dart';
import '../models/parent_notification_model.dart';

class ParentNotificationRepositoryImpl implements ParentNotificationRepository {
  const ParentNotificationRepositoryImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<ParentNotificationEntity>> getNotifications({
    required String parentId,
    String? studentId,
    ParentNotificationType? type,
    bool? isRead,
  }) async {
    final snapshot = await _service
        .collection(FirestorePaths.parentNotifications)
        .get();

    final values =
        snapshot.docs
            .map(
              (doc) => ParentNotificationModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }),
            )
            .where(
              (item) =>
                  item.parentId == parentId &&
                  (studentId == null || item.studentId == studentId) &&
                  (type == null || item.type == type) &&
                  (isRead == null || item.isRead == isRead),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return List.unmodifiable(values);
  }

  @override
  Future<void> saveNotification(ParentNotificationEntity notification) {
    return _service
        .collection(FirestorePaths.parentNotifications)
        .doc(notification.id)
        .set(ParentNotificationModel.fromEntity(notification).toMap());
  }

  @override
  Future<void> markRead(String id) async {
    await _service
        .collection(FirestorePaths.parentNotifications)
        .doc(id)
        .update({'isRead': true, 'readAt': Timestamp.fromDate(DateTime.now())});
  }

  @override
  Future<void> markAllRead({
    required String parentId,
    String? studentId,
  }) async {
    final values = await getNotifications(
      parentId: parentId,
      studentId: studentId,
      isRead: false,
    );

    for (final item in values) {
      await markRead(item.id);
    }
  }

  @override
  Future<void> deleteNotification(String id) {
    return _service
        .collection(FirestorePaths.parentNotifications)
        .doc(id)
        .delete();
  }

  @override
  String generateId() {
    return _service.collection(FirestorePaths.parentNotifications).doc().id;
  }
}
