class DocumentBrandingEntity {
  const DocumentBrandingEntity({
    required this.schoolName,
    required this.schoolLogoUrl,
    required this.principalName,
    required this.principalDesignation,
    required this.principalSignatureUrl,
    required this.schoolStampUrl,
  });

  final String schoolName;
  final String schoolLogoUrl;

  final String principalName;
  final String principalDesignation;
  final String principalSignatureUrl;

  final String schoolStampUrl;

  bool get hasSchoolLogo =>
      schoolLogoUrl.trim().isNotEmpty;

  bool get hasPrincipalSignature =>
      principalSignatureUrl.trim().isNotEmpty;

  bool get hasSchoolStamp =>
      schoolStampUrl.trim().isNotEmpty;

  DocumentBrandingEntity copyWith({
    String? schoolName,
    String? schoolLogoUrl,
    String? principalName,
    String? principalDesignation,
    String? principalSignatureUrl,
    String? schoolStampUrl,
  }) {
    return DocumentBrandingEntity(
      schoolName:
          schoolName ?? this.schoolName,
      schoolLogoUrl:
          schoolLogoUrl ?? this.schoolLogoUrl,
      principalName:
          principalName ?? this.principalName,
      principalDesignation:
          principalDesignation ??
          this.principalDesignation,
      principalSignatureUrl:
          principalSignatureUrl ??
          this.principalSignatureUrl,
      schoolStampUrl:
          schoolStampUrl ?? this.schoolStampUrl,
    );
  }
}
