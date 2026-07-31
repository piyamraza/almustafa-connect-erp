import '../repositories/exam_repository.dart';

class DeleteExam {
  const DeleteExam(this._repository);

  final ExamRepository _repository;

  Future<void> call(String id) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Exam ID cannot be empty.');
    }
    return _repository.deleteExam(normalizedId);
  }
}
