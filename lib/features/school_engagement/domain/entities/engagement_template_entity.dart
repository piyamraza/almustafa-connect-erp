enum EngagementType {
  birthday,
  graduation,
  eid,
  teacherDay,
  sportsDay,
  themeDay,
  other,
}

enum EngagementTargetGender { male, female, any }

class EngagementTemplateEntity {
  final String id;
  final String name;
  final EngagementType engagementType;
  final String templateVariant;
  final EngagementTargetGender targetGender;

  final String backgroundAsset;
  final String frameAsset;

  final String greeting;
  final String wishText;

  final bool isActive;
  final bool isDefault;

  final DateTime createdAt;
  final DateTime updatedAt;

  const EngagementTemplateEntity({
    required this.id,
    required this.name,
    required this.engagementType,
    required this.templateVariant,
    required this.targetGender,
    required this.backgroundAsset,
    required this.frameAsset,
    required this.greeting,
    required this.wishText,
    required this.isActive,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isBirthdayTemplate => engagementType == EngagementType.birthday;

  bool get isForMale => targetGender == EngagementTargetGender.male;

  bool get isForFemale => targetGender == EngagementTargetGender.female;

  bool get isForAnyGender => targetGender == EngagementTargetGender.any;

  EngagementTemplateEntity copyWith({
    String? id,
    String? name,
    EngagementType? engagementType,
    String? templateVariant,
    EngagementTargetGender? targetGender,
    String? backgroundAsset,
    String? frameAsset,
    String? greeting,
    String? wishText,
    bool? isActive,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EngagementTemplateEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      engagementType: engagementType ?? this.engagementType,
      templateVariant: templateVariant ?? this.templateVariant,
      targetGender: targetGender ?? this.targetGender,
      backgroundAsset: backgroundAsset ?? this.backgroundAsset,
      frameAsset: frameAsset ?? this.frameAsset,
      greeting: greeting ?? this.greeting,
      wishText: wishText ?? this.wishText,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
