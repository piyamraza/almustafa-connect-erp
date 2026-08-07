import '../entities/engagement_history_entity.dart';
import '../entities/engagement_template_entity.dart';
import '../repositories/engagement_repository.dart';

class GetBirthdayHistory {
  const GetBirthdayHistory({required this._repository});

  final EngagementRepository _repository;

  Future<List<EngagementHistoryEntity>> call({
    String? personId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getHistory(
      engagementType: EngagementType.birthday,
      personId: personId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
