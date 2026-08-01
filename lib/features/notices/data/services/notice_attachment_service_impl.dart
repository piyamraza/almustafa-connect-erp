import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/notice_entity.dart';
import '../../domain/services/notice_attachment_service.dart';

class NoticeAttachmentServiceImpl implements NoticeAttachmentService {
  NoticeAttachmentServiceImpl(this._storage);

  final FirebaseStorage _storage;
  final Uuid _uuid = const Uuid();

  static const allowedExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'jpg',
    'jpeg',
    'png',
    'zip',
  ];

  @override
  Future<List<NoticeAttachmentEntity>> pickAndUpload({
    required String noticeId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result == null) return const [];

    final uploaded = <NoticeAttachmentEntity>[];

    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) {
        throw StateError('Unable to read ${file.name}.');
      }
      if (file.size > 15 * 1024 * 1024) {
        throw StateError('${file.name} exceeds the 15 MB limit.');
      }

      final id = _uuid.v4();
      final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final storagePath = 'notices/$noticeId/$id-$safeName';
      final reference = _storage.ref(storagePath);

      await reference.putData(bytes);

      uploaded.add(
        NoticeAttachmentEntity(
          id: id,
          fileName: file.name,
          fileUrl: await reference.getDownloadURL(),
          fileType: file.extension?.toLowerCase() ?? 'file',
          fileSize: file.size,
          storagePath: storagePath,
        ),
      );
    }

    return uploaded;
  }

  @override
  Future<void> deleteAttachment(NoticeAttachmentEntity attachment) async {
    if (attachment.storagePath.isEmpty) return;
    await _storage.ref(attachment.storagePath).delete();
  }
}
