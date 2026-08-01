import '../entities/notice_entity.dart';

abstract class NoticeRepository {
  Future<List<NoticeEntity>> getNotices({
    required String academicSession,
    NoticeStatus? status,
    NoticeAudienceType? audienceType,
    NoticePriority? priority,
  });

  Future<void> saveNotice(NoticeEntity notice);

  Future<void> deleteNotice(String id);

  String generateId();
}
