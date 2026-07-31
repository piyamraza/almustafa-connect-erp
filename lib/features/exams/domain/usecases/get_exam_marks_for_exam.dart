import '../entities/exam_mark_entity.dart';
import '../repositories/exam_mark_repository.dart';

class GetExamMarksForExam {
  const GetExamMarksForExam(this._repository);

  final ExamMarkRepository _repository;

  Future<List<ExamMarkEntity>> call(String examId) {
    return _repository.getMarksForExam(examId);
  }
}
