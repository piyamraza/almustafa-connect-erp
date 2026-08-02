import '../entities/exam_result_entity.dart';

abstract class ExamResultRepository {
  Future<List<ExamResultEntity>> getResultsForExam(String examId);

  /// Returns only records visible outside the Examination module.
  ///
  /// Published and locked results remain visible to the Parent Portal.
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
    String actorId = '',
    String reason = '',
    bool setPublishedAt = true,
  });
}