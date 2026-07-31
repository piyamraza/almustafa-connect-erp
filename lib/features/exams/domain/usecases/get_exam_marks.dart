import '../entities/exam_mark_entity.dart';
import '../repositories/exam_mark_repository.dart';

class GetExamMarks {
  GetExamMarks(this._repository);

  final ExamMarkRepository _repository;

  Future<List<ExamMarkEntity>> call(String entryKey) {
    return _repository.getMarksForEntry(entryKey);
  }
}
