import '../entities/homework_entity.dart';

abstract class HomeworkAttachmentService {
  Future<List<HomeworkAttachmentEntity>> pickAndUpload({
    required String homeworkId,
  });

  Future<void> deleteAttachment(HomeworkAttachmentEntity attachment);
}
