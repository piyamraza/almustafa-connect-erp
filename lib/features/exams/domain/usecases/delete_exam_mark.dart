import '../repositories/exam_mark_repository.dart';

class DeleteExamMark {
  DeleteExamMark(this._repository);

  final ExamMarkRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteMark(id);
  }
}
