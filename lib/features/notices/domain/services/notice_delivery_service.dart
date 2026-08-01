import '../entities/notice_entity.dart';

abstract class NoticeDeliveryService {
  Future<void> shareNotice(NoticeEntity notice);

  Future<int> processScheduledNotices({required String academicSession});
}
