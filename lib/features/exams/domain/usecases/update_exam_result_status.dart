import '../entities/exam_result_entity.dart';
import '../repositories/exam_result_repository.dart';

class UpdateExamResultStatus {
  const UpdateExamResultStatus(this._repository);

  final ExamResultRepository _repository;

  Future<void> call({
    required List<String> resultIds,
    required ResultStatus status,
    bool setPublishedAt = true,
  }) {
    return _repository.updateStatus(
      resultIds: resultIds,
      status: status,
      setPublishedAt: setPublishedAt,
    );
  }
}
