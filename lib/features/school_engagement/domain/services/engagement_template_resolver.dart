import '../entities/engagement_person_entity.dart';
import '../entities/engagement_template_entity.dart';

class EngagementTemplateResolver {
  const EngagementTemplateResolver();

  EngagementTemplateEntity? resolve({
    required List<EngagementTemplateEntity> templates,
    required EngagementType engagementType,
    required EngagementPersonEntity person,
  }) {
    final activeTemplates = templates.where(
      (template) =>
          template.isActive && template.engagementType == engagementType,
    );

    if (activeTemplates.isEmpty) {
      return null;
    }

    final targetGender = _resolveGender(person);

    final genderTemplates = activeTemplates.where(
      (template) => template.targetGender == targetGender,
    );

    final genderDefault = _firstDefault(genderTemplates);

    if (genderDefault != null) {
      return genderDefault;
    }

    final genderTemplate = _firstOrNull(genderTemplates);

    if (genderTemplate != null) {
      return genderTemplate;
    }

    final anyGenderTemplates = activeTemplates.where(
      (template) => template.targetGender == EngagementTargetGender.any,
    );

    final anyGenderDefault = _firstDefault(anyGenderTemplates);

    if (anyGenderDefault != null) {
      return anyGenderDefault;
    }

    return _firstOrNull(anyGenderTemplates) ??
        _firstDefault(activeTemplates) ??
        _firstOrNull(activeTemplates);
  }

  EngagementTargetGender _resolveGender(EngagementPersonEntity person) {
    if (person.isMale) {
      return EngagementTargetGender.male;
    }

    if (person.isFemale) {
      return EngagementTargetGender.female;
    }

    return EngagementTargetGender.any;
  }

  EngagementTemplateEntity? _firstDefault(
    Iterable<EngagementTemplateEntity> templates,
  ) {
    for (final template in templates) {
      if (template.isDefault) {
        return template;
      }
    }

    return null;
  }

  EngagementTemplateEntity? _firstOrNull(
    Iterable<EngagementTemplateEntity> templates,
  ) {
    for (final template in templates) {
      return template;
    }

    return null;
  }
}
