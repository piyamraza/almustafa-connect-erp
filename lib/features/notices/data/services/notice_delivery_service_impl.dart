import 'package:share_plus/share_plus.dart';

import '../../domain/entities/notice_entity.dart';
import '../../domain/repositories/notice_repository.dart';
import '../../domain/services/notice_delivery_service.dart';

class NoticeDeliveryServiceImpl implements NoticeDeliveryService {
  const NoticeDeliveryServiceImpl(this._repository);

  final NoticeRepository _repository;

  @override
  Future<void> shareNotice(NoticeEntity notice) async {
    final buffer = StringBuffer()
      ..writeln(notice.title)
      ..writeln()
      ..writeln(notice.message)
      ..writeln()
      ..writeln('Priority: ${notice.priority.name.toUpperCase()}');

    if (notice.expireAt != null) {
      buffer.writeln('Valid until: ${_date(notice.expireAt!)}');
    }

    for (final attachment in notice.attachments) {
      if (attachment.fileUrl.isNotEmpty) {
        buffer.writeln(attachment.fileUrl);
      }
    }

    await Share.share(buffer.toString(), subject: notice.title);
  }

  @override
  Future<int> processScheduledNotices({required String academicSession}) async {
    final values = await _repository.getNotices(
      academicSession: academicSession,
    );
    final now = DateTime.now();
    var changed = 0;

    for (final notice in values) {
      if (notice.status == NoticeStatus.scheduled &&
          notice.publishAt != null &&
          !notice.publishAt!.isAfter(now)) {
        await _repository.saveNotice(
          notice.copyWith(
            status: NoticeStatus.published,
            updatedAt: now,
            updatedBy: 'System',
            publishedAt: now,
            publishedBy: 'System',
          ),
        );
        changed++;
      } else if ((notice.status == NoticeStatus.published ||
              notice.status == NoticeStatus.scheduled) &&
          notice.expireAt != null &&
          !notice.expireAt!.isAfter(now)) {
        await _repository.saveNotice(
          notice.copyWith(
            status: NoticeStatus.expired,
            updatedAt: now,
            updatedBy: 'System',
          ),
        );
        changed++;
      }
    }

    return changed;
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
