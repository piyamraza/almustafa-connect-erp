import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/portal_notification_entity.dart';
import '../../domain/repositories/portal_notification_repository.dart';

class PortalNotificationRepositoryImpl implements PortalNotificationRepository {
  const PortalNotificationRepositoryImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<PortalNotificationEntity>> getNotifications({
    required PortalRecipientType recipientType,
    required String recipientId,
    bool? isRead,
  }) async {
    final snapshot = await _service
        .collection(FirestorePaths.portalNotifications)
        .where('recipientType', isEqualTo: recipientType.name)
        .where('recipientId', isEqualTo: recipientId)
        .get();
    final values =
        snapshot.docs
            .map((doc) => _fromMap({...doc.data(), 'id': doc.id}))
            .where(
              (item) =>
                  item.recipientType == recipientType &&
                  item.recipientId == recipientId &&
                  (isRead == null || item.isRead == isRead),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(values);
  }

  @override
  Future<void> create({
    required PortalRecipientType recipientType,
    required String recipientId,
    required String title,
    required String message,
    required PortalNotificationType type,
    String referenceId = '',
    String studentId = '',
  }) async {
    if (recipientId.trim().isEmpty) return;
    final id = generateId();
    await _service.collection(FirestorePaths.portalNotifications).doc(id).set({
      'recipientType': recipientType.name,
      'recipientId': recipientId.trim(),
      'title': title.trim(),
      'message': message.trim(),
      'type': type.name,
      'referenceId': referenceId.trim(),
      'studentId': studentId.trim(),
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'readAt': null,
    });
  }

  @override
  Future<void> markRead(String id) => _service
      .collection(FirestorePaths.portalNotifications)
      .doc(id)
      .update({'isRead': true, 'readAt': Timestamp.fromDate(DateTime.now())});

  @override
  Future<void> markAllRead({
    required PortalRecipientType recipientType,
    required String recipientId,
  }) async {
    final values = await getNotifications(
      recipientType: recipientType,
      recipientId: recipientId,
      isRead: false,
    );
    for (final item in values) {
      await markRead(item.id);
    }
  }

  @override
  String generateId() =>
      _service.collection(FirestorePaths.portalNotifications).doc().id;

  static PortalNotificationEntity _fromMap(Map<String, dynamic> map) {
    return PortalNotificationEntity(
      id: map['id']?.toString() ?? '',
      recipientType: PortalRecipientType.values.firstWhere(
        (value) => value.name == map['recipientType'],
        orElse: () => PortalRecipientType.admin,
      ),
      recipientId: map['recipientId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: PortalNotificationType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => PortalNotificationType.general,
      ),
      referenceId: map['referenceId']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      isRead: map['isRead'] == true,
      createdAt: _date(map['createdAt']),
      readAt: map['readAt'] == null ? null : _date(map['readAt']),
    );
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
