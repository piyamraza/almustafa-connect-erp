import '../../domain/entities/school_branding_entity.dart';

class SchoolBrandingModel extends SchoolBrandingEntity {
  const SchoolBrandingModel({
    required super.schoolName,
    required super.schoolLogoUrl,
    required super.principalName,
    required super.principalDesignation,
    required super.principalSignatureUrl,
    required super.principalSignatureSource,
    required super.updatedAt,
  });

  factory SchoolBrandingModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return SchoolBrandingModel(
      schoolName: map['schoolName'] as String? ?? '',
      schoolLogoUrl: map['schoolLogoUrl'] as String? ?? '',
      principalName: map['principalName'] as String? ?? '',
      principalDesignation:
          map['principalDesignation'] as String? ?? '',
      principalSignatureUrl:
          map['principalSignatureUrl'] as String? ?? '',
      principalSignatureSource:
          _signatureSourceFromString(
        map['principalSignatureSource'] as String? ?? '',
      ),
      updatedAt: _dateTimeFromValue(
        map['updatedAt'],
      ),
    );
  }

  factory SchoolBrandingModel.fromEntity(
    SchoolBrandingEntity entity,
  ) {
    return SchoolBrandingModel(
      schoolName: entity.schoolName,
      schoolLogoUrl: entity.schoolLogoUrl,
      principalName: entity.principalName,
      principalDesignation:
          entity.principalDesignation,
      principalSignatureUrl:
          entity.principalSignatureUrl,
      principalSignatureSource:
          entity.principalSignatureSource,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolName': schoolName,
      'schoolLogoUrl': schoolLogoUrl,
      'principalName': principalName,
      'principalDesignation':
          principalDesignation,
      'principalSignatureUrl':
          principalSignatureUrl,
      'principalSignatureSource':
          principalSignatureSource.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static PrincipalSignatureSource
      _signatureSourceFromString(
    String value,
  ) {
    return PrincipalSignatureSource.values.firstWhere(
      (item) => item.name == value,
      orElse: () => PrincipalSignatureSource.none,
    );
  }

  static DateTime _dateTimeFromValue(
    dynamic value,
  ) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
