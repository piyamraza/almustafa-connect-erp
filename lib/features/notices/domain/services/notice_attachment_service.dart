import '../entities/notice_entity.dart';

abstract class NoticeAttachmentService {
  Future<List<NoticeAttachmentEntity>> pickAndUpload({
    required String noticeId,
  });

  Future<void> deleteAttachment(NoticeAttachmentEntity attachment);
}
