enum EngagementPersonType { student, teacher, staff, principal, parent, other }

class EngagementPersonEntity {
  final String id;
  final EngagementPersonType personType;
  final String displayName;
  final String gender;
  final DateTime dateOfBirth;
  final String profileImageUrl;

  final String? classId;
  final String? sectionId;
  final String? className;
  final String? sectionName;

  final bool isActive;
  final String sourceReference;

  const EngagementPersonEntity({
    required this.id,
    required this.personType,
    required this.displayName,
    required this.gender,
    required this.dateOfBirth,
    required this.profileImageUrl,
    this.classId,
    this.sectionId,
    this.className,
    this.sectionName,
    required this.isActive,
    required this.sourceReference,
  });

  bool get isMale => gender.trim().toLowerCase() == 'male';

  bool get isFemale => gender.trim().toLowerCase() == 'female';

  String get classSectionLabel {
    final classValue = className?.trim() ?? '';
    final sectionValue = sectionName?.trim() ?? '';

    if (classValue.isEmpty && sectionValue.isEmpty) {
      return '';
    }

    if (classValue.isEmpty) {
      return sectionValue;
    }

    if (sectionValue.isEmpty) {
      return classValue;
    }

    return '$classValue - $sectionValue';
  }

  EngagementPersonEntity copyWith({
    String? id,
    EngagementPersonType? personType,
    String? displayName,
    String? gender,
    DateTime? dateOfBirth,
    String? profileImageUrl,
    String? classId,
    String? sectionId,
    String? className,
    String? sectionName,
    bool? isActive,
    String? sourceReference,
  }) {
    return EngagementPersonEntity(
      id: id ?? this.id,
      personType: personType ?? this.personType,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      className: className ?? this.className,
      sectionName: sectionName ?? this.sectionName,
      isActive: isActive ?? this.isActive,
      sourceReference: sourceReference ?? this.sourceReference,
    );
  }
}
