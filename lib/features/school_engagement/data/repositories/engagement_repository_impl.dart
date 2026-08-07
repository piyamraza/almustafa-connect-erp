import '../../domain/entities/engagement_history_entity.dart';
import '../../domain/entities/engagement_template_entity.dart';
import '../../domain/repositories/engagement_repository.dart';
import '../datasources/engagement_remote_datasource.dart';
import '../models/engagement_history_model.dart';
import '../models/engagement_template_model.dart';

class EngagementRepositoryImpl implements EngagementRepository {
  const EngagementRepositoryImpl(this._remoteDataSource);

  final EngagementRemoteDataSource _remoteDataSource;

  @override
  Future<List<EngagementTemplateEntity>> getTemplates({
    EngagementType? engagementType,
    bool activeOnly = true,
  }) async {
    final templates = await _remoteDataSource.getTemplates();

    final filtered =
        templates.where((template) {
          final matchesType =
              engagementType == null ||
              template.engagementType == engagementType;

          final matchesActive = !activeOnly || template.isActive;

          return matchesType && matchesActive;
        }).toList()..sort((a, b) {
          if (a.isDefault != b.isDefault) {
            return a.isDefault ? -1 : 1;
          }

          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

    return List.unmodifiable(filtered);
  }

  @override
  Future<EngagementTemplateEntity?> getTemplateById(String templateId) async {
    final templates = await _remoteDataSource.getTemplates();

    for (final template in templates) {
      if (template.id == templateId) {
        return template;
      }
    }

    return null;
  }

  @override
  Future<void> saveTemplate(EngagementTemplateEntity template) {
    return _remoteDataSource.saveTemplate(
      EngagementTemplateModel.fromEntity(template),
    );
  }

  @override
  Future<List<EngagementHistoryEntity>> getHistory({
    EngagementType? engagementType,
    String? personId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final history = await _remoteDataSource.getHistory();

    final filtered = history.where((item) {
      if (engagementType != null && item.engagementType != engagementType) {
        return false;
      }

      if (personId != null &&
          personId.trim().isNotEmpty &&
          item.personId != personId) {
        return false;
      }

      if (startDate != null && item.eventDate.isBefore(_dateOnly(startDate))) {
        return false;
      }

      if (endDate != null && item.eventDate.isAfter(_endOfDay(endDate))) {
        return false;
      }

      return true;
    }).toList()..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

    return List.unmodifiable(filtered);
  }

  @override
  Future<void> recordHistory(EngagementHistoryEntity history) {
    return _remoteDataSource.saveHistory(
      EngagementHistoryModel.fromEntity(history),
    );
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }
}
