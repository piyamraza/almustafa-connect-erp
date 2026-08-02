import '../entities/exam_result_entity.dart';
import '../repositories/exam_result_repository.dart';

class UpdateExamResultStatus {
  const UpdateExamResultStatus(this._repository);

  final ExamResultRepository _repository;

  Future<void> call({
    required List<String> resultIds,
    required ResultStatus status,
    String actorId = '',
    String reason = '',
    bool setPublishedAt = true,
  }) {
    final normalizedIds = resultIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedIds.isEmpty) {
      throw ArgumentError(
        'Select at least one result before changing status.',
      );
    }

    final normalizedActorId = actorId.trim();
    final normalizedReason = reason.trim();

    if (status == ResultStatus.published &&
        normalizedActorId.isEmpty) {
      throw ArgumentError(
        'Published-by user ID is required.',
      );
    }

    if (status == ResultStatus.locked &&
        normalizedActorId.isEmpty) {
      throw ArgumentError(
        'Locked-by user ID is required.',
      );
    }

    return _repository.updateStatus(
      resultIds: normalizedIds,
      status: status,
      actorId: normalizedActorId,
      reason: normalizedReason,
      setPublishedAt: setPublishedAt,
    );
  }
}