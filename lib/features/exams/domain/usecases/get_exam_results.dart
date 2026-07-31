import '../entities/exam_result_entity.dart';
import '../repositories/exam_result_repository.dart';

class GetExamResults {
  const GetExamResults(this._repository);

  final ExamResultRepository _repository;

  Future<List<ExamResultEntity>> call(String examId) {
    return _repository.getResultsForExam(examId);
  }
}
