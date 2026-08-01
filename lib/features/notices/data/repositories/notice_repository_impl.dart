import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/notice_entity.dart';
import '../../domain/repositories/notice_repository.dart';
import '../models/notice_model.dart';

class NoticeRepositoryImpl implements NoticeRepository {
  const NoticeRepositoryImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<NoticeEntity>> getNotices({
    required String academicSession,
    NoticeStatus? status,
    NoticeAudienceType? audienceType,
    NoticePriority? priority,
  }) async {
    final snapshot = await _service.collection(FirestorePaths.notices).get();

    final values =
        snapshot.docs
            .map((doc) => NoticeModel.fromMap({...doc.data(), 'id': doc.id}))
            .where(
              (item) =>
                  item.academicSession == academicSession &&
                  (status == null || item.status == status) &&
                  (audienceType == null || item.audienceType == audienceType) &&
                  (priority == null || item.priority == priority),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return List.unmodifiable(values);
  }

  @override
  Future<void> saveNotice(NoticeEntity notice) async {
    if (notice.title.trim().isEmpty) {
      throw StateError('Notice title is required.');
    }
    if (notice.message.trim().isEmpty) {
      throw StateError('Notice message is required.');
    }
    if (notice.expireAt != null &&
        notice.publishAt != null &&
        notice.expireAt!.isBefore(notice.publishAt!)) {
      throw StateError('Expiry date cannot be before publish date.');
    }
    if (notice.audienceType == NoticeAudienceType.selectedClasses &&
        notice.classIds.isEmpty) {
      throw StateError('Select at least one class.');
    }

    await _service
        .collection(FirestorePaths.notices)
        .doc(notice.id)
        .set(NoticeModel.fromEntity(notice).toMap());
  }

  @override
  Future<void> deleteNotice(String id) {
    return _service.collection(FirestorePaths.notices).doc(id).delete();
  }

  @override
  String generateId() {
    return _service.collection(FirestorePaths.notices).doc().id;
  }
}
