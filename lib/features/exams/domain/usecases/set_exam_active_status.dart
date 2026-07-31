import '../repositories/exam_repository.dart';

class SetExamActiveStatus {
  const SetExamActiveStatus(this._repository);

  final ExamRepository _repository;

  Future<void> call({required String id, required bool isActive}) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Exam ID cannot be empty.');
    }
    return _repository.setExamActiveStatus(
      id: normalizedId,
      isActive: isActive,
    );
  }
}
