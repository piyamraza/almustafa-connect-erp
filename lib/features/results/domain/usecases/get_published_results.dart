import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/domain/repositories/exam_result_repository.dart';

/// Read-only boundary for the Results module. The underlying repository returns
/// only published records and locked records, which are published but immutable.
class GetPublishedResults {
  const GetPublishedResults(this._repository);

  final ExamResultRepository _repository;

  Future<List<ExamResultEntity>> call({
    String? examId,
    String? classId,
    String? sectionId,
    String? studentId,
  }) {
    return _repository.getPublishedResults(
      examId: examId,
      classId: classId,
      sectionId: sectionId,
      studentId: studentId,
    );
  }
}
