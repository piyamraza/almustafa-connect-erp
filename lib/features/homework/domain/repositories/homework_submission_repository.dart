import '../entities/homework_submission_entity.dart';

abstract class HomeworkSubmissionRepository {
  Future<List<HomeworkSubmissionEntity>> getSubmissions({
    String? homeworkId,
    String? studentId,
    String? classId,
    String? sectionId,
    HomeworkSubmissionStatus? status,
  });

  Future<void> saveSubmission(HomeworkSubmissionEntity submission);

  Future<void> deleteSubmission(String id);

  String generateId();
}
