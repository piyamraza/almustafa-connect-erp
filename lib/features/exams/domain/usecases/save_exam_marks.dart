import '../entities/exam_mark_entity.dart';
import '../repositories/exam_mark_repository.dart';

class SaveExamMarks {
  SaveExamMarks(this._repository);

  final ExamMarkRepository _repository;

  Future<void> call(List<ExamMarkEntity> marks) {
    return _repository.saveMarks(marks);
  }
}
