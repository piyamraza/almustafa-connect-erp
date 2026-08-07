import '../../domain/entities/engagement_template_entity.dart';

class EngagementTemplateModel extends EngagementTemplateEntity {
  const EngagementTemplateModel({
    required super.id,
    required super.name,
    required super.engagementType,
    required super.templateVariant,
    required super.targetGender,
    required super.backgroundAsset,
    required super.frameAsset,
    required super.greeting,
    required super.wishText,
    required super.isActive,
    required super.isDefault,
    required super.createdAt,
    required super.updatedAt,
  });

  factory EngagementTemplateModel.fromMap(Map<String, dynamic> map) {
    return EngagementTemplateModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      engagementType: _engagementTypeFromString(
        map['engagementType'] as String? ?? '',
      ),
      templateVariant: map['templateVariant'] as String? ?? '',
      targetGender: _targetGenderFromString(
        map['targetGender'] as String? ?? '',
      ),
      backgroundAsset: map['backgroundAsset'] as String? ?? '',
      frameAsset: map['frameAsset'] as String? ?? '',
      greeting: map['greeting'] as String? ?? '',
      wishText: map['wishText'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: _dateTimeFromValue(map['createdAt']),
      updatedAt: _dateTimeFromValue(map['updatedAt']),
    );
  }

  factory EngagementTemplateModel.fromEntity(EngagementTemplateEntity entity) {
    return EngagementTemplateModel(
      id: entity.id,
      name: entity.name,
      engagementType: entity.engagementType,
      templateVariant: entity.templateVariant,
      targetGender: entity.targetGender,
      backgroundAsset: entity.backgroundAsset,
      frameAsset: entity.frameAsset,
      greeting: entity.greeting,
      wishText: entity.wishText,
      isActive: entity.isActive,
      isDefault: entity.isDefault,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'engagementType': engagementType.name,
      'templateVariant': templateVariant,
      'targetGender': targetGender.name,
      'backgroundAsset': backgroundAsset,
      'frameAsset': frameAsset,
      'greeting': greeting,
      'wishText': wishText,
      'isActive': isActive,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static EngagementType _engagementTypeFromString(String value) {
    return EngagementType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => EngagementType.other,
    );
  }

  static EngagementTargetGender _targetGenderFromString(String value) {
    return EngagementTargetGender.values.firstWhere(
      (item) => item.name == value,
      orElse: () => EngagementTargetGender.any,
    );
  }

  static DateTime _dateTimeFromValue(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
