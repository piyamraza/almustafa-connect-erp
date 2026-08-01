import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/homework_entity.dart';
import '../../domain/services/homework_attachment_service.dart';

class HomeworkAttachmentServiceImpl implements HomeworkAttachmentService {
  HomeworkAttachmentServiceImpl(this._storage);

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
  Future<List<HomeworkAttachmentEntity>> pickAndUpload({
    required String homeworkId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result == null) return const [];

    final uploaded = <HomeworkAttachmentEntity>[];

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
      final storagePath = 'homework/$homeworkId/$id-$safeName';
      final reference = _storage.ref(storagePath);

      await reference.putData(
        bytes,
        SettableMetadata(contentType: _contentType(file.extension)),
      );

      uploaded.add(
        HomeworkAttachmentEntity(
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
  Future<void> deleteAttachment(HomeworkAttachmentEntity attachment) async {
    if (attachment.storagePath.isEmpty) return;
    await _storage.ref(attachment.storagePath).delete();
  }

  String _contentType(String? extension) => switch (extension?.toLowerCase()) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'zip' => 'application/zip',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt' => 'application/vnd.ms-powerpoint',
    'pptx' =>
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    _ => 'application/octet-stream',
  };
}
