import '../entities/notice_receipt_entity.dart';

abstract class NoticeReceiptRepository {
  Future<List<NoticeReceiptEntity>> getReceipts({
    String? noticeId,
    String? recipientId,
    NoticeDeliveryStatus? status,
  });

  Future<void> saveReceipt(NoticeReceiptEntity receipt);

  String generateId();
}
