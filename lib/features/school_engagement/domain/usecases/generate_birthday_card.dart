import '../entities/engagement_person_entity.dart';
import '../entities/engagement_template_entity.dart';
import '../repositories/engagement_repository.dart';
import '../services/engagement_template_resolver.dart';

class GenerateBirthdayCard {
  const GenerateBirthdayCard({
    required this._repository,
    required this._templateResolver,
  });

  final EngagementRepository _repository;
  final EngagementTemplateResolver _templateResolver;

  Future<EngagementTemplateEntity> call({
    required EngagementPersonEntity person,
  }) async {
    final templates = await _repository.getTemplates(
      engagementType: EngagementType.birthday,
      activeOnly: true,
    );

    final template = _templateResolver.resolve(
      templates: templates,
      engagementType: EngagementType.birthday,
      person: person,
    );

    if (template == null) {
      throw StateError(
        'No active birthday template is available for ${person.displayName}.',
      );
    }

    return template;
  }
}
