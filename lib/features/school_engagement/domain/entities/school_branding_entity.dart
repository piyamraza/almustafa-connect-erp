enum PrincipalSignatureSource {
  uploaded,
  drawn,
  none,
}

class SchoolBrandingEntity {
  final String schoolName;
  final String schoolLogoUrl;

  final String principalName;
  final String principalDesignation;

  final String principalSignatureUrl;
  final PrincipalSignatureSource principalSignatureSource;

  final DateTime updatedAt;

  const SchoolBrandingEntity({
    required this.schoolName,
    required this.schoolLogoUrl,
    required this.principalName,
    required this.principalDesignation,
    required this.principalSignatureUrl,
    required this.principalSignatureSource,
    required this.updatedAt,
  });

  bool get hasSchoolLogo =>
      schoolLogoUrl.trim().isNotEmpty;

  bool get hasPrincipalSignature =>
      principalSignatureUrl.trim().isNotEmpty &&
      principalSignatureSource != PrincipalSignatureSource.none;

  SchoolBrandingEntity copyWith({
    String? schoolName,
    String? schoolLogoUrl,
    String? principalName,
    String? principalDesignation,
    String? principalSignatureUrl,
    PrincipalSignatureSource? principalSignatureSource,
    DateTime? updatedAt,
  }) {
    return SchoolBrandingEntity(
      schoolName: schoolName ?? this.schoolName,
      schoolLogoUrl: schoolLogoUrl ?? this.schoolLogoUrl,
      principalName: principalName ?? this.principalName,
      principalDesignation:
          principalDesignation ?? this.principalDesignation,
      principalSignatureUrl:
          principalSignatureUrl ?? this.principalSignatureUrl,
      principalSignatureSource:
          principalSignatureSource ??
          this.principalSignatureSource,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
