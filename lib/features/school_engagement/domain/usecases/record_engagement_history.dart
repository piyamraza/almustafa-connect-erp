import '../entities/engagement_history_entity.dart';
import '../repositories/engagement_repository.dart';

class RecordEngagementHistory {
  const RecordEngagementHistory({required this._repository});

  final EngagementRepository _repository;

  Future<void> call(EngagementHistoryEntity history) async {
    if (!history.hasAnyAction) {
      return;
    }

    await _repository.recordHistory(history);
  }
}
