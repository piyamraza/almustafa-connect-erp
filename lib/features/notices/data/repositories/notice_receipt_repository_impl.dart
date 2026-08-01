import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/notice_receipt_entity.dart';
import '../../domain/repositories/notice_receipt_repository.dart';
import '../models/notice_receipt_model.dart';

class NoticeReceiptRepositoryImpl implements NoticeReceiptRepository {
  const NoticeReceiptRepositoryImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<NoticeReceiptEntity>> getReceipts({
    String? noticeId,
    String? recipientId,
    NoticeDeliveryStatus? status,
  }) async {
    final snapshot = await _service
        .collection(FirestorePaths.noticeReceipts)
        .get();

    final values =
        snapshot.docs
            .map(
              (doc) =>
                  NoticeReceiptModel.fromMap({...doc.data(), 'id': doc.id}),
            )
            .where(
              (item) =>
                  (noticeId == null || item.noticeId == noticeId) &&
                  (recipientId == null || item.recipientId == recipientId) &&
                  (status == null || item.status == status),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return List.unmodifiable(values);
  }

  @override
  Future<void> saveReceipt(NoticeReceiptEntity receipt) {
    return _service
        .collection(FirestorePaths.noticeReceipts)
        .doc(receipt.id)
        .set(NoticeReceiptModel.fromEntity(receipt).toMap());
  }

  @override
  String generateId() {
    return _service.collection(FirestorePaths.noticeReceipts).doc().id;
  }
}
