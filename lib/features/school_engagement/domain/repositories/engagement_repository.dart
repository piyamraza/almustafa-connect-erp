import '../entities/engagement_history_entity.dart';
import '../entities/engagement_template_entity.dart';

abstract class EngagementRepository {
  Future<List<EngagementTemplateEntity>> getTemplates({
    EngagementType? engagementType,
    bool activeOnly = true,
  });

  Future<EngagementTemplateEntity?> getTemplateById(String templateId);

  Future<void> saveTemplate(EngagementTemplateEntity template);

  Future<List<EngagementHistoryEntity>> getHistory({
    EngagementType? engagementType,
    String? personId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<void> recordHistory(EngagementHistoryEntity history);
}
