import '../entities/exam_result_entity.dart';

abstract class ExamResultRepository {
  Future<List<ExamResultEntity>> getResultsForExam(String examId);

  /// Returns records that are visible outside the Examination module.
  /// A locked record remains published but is immutable.
  Future<List<ExamResultEntity>> getPublishedResults({
    String? examId,
    String? classId,
    String? sectionId,
    String? studentId,
  });

  Future<void> saveResults(List<ExamResultEntity> results);

  Future<void> updateStatus({
    required List<String> resultIds,
    required ResultStatus status,
    bool setPublishedAt = true,
  });
}
