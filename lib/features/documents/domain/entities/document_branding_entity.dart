class DocumentBrandingEntity {
  const DocumentBrandingEntity({
    required this.schoolName,
    required this.schoolLogoUrl,
    required this.principalName,
    required this.principalDesignation,
    required this.principalSignatureUrl,
    this.principalSignatureData = '',
    required this.schoolStampUrl,
    this.schoolStampData = '',
  });

  final String schoolName;
  final String schoolLogoUrl;

  final String principalName;
  final String principalDesignation;
  final String principalSignatureUrl;
  final String principalSignatureData;

  final String schoolStampUrl;
  final String schoolStampData;

  bool get hasSchoolLogo => schoolLogoUrl.trim().isNotEmpty;

  bool get hasPrincipalSignature => principalSignatureUrl.trim().isNotEmpty;

  bool get hasSchoolStamp => schoolStampUrl.trim().isNotEmpty;

  DocumentBrandingEntity copyWith({
    String? schoolName,
    String? schoolLogoUrl,
    String? principalName,
    String? principalDesignation,
    String? principalSignatureUrl,
    String? principalSignatureData,
    String? schoolStampUrl,
    String? schoolStampData,
  }) {
    return DocumentBrandingEntity(
      schoolName: schoolName ?? this.schoolName,
      schoolLogoUrl: schoolLogoUrl ?? this.schoolLogoUrl,
      principalName: principalName ?? this.principalName,
      principalDesignation: principalDesignation ?? this.principalDesignation,
      principalSignatureUrl:
          principalSignatureUrl ?? this.principalSignatureUrl,
      principalSignatureData:
          principalSignatureData ?? this.principalSignatureData,
      schoolStampUrl: schoolStampUrl ?? this.schoolStampUrl,
      schoolStampData: schoolStampData ?? this.schoolStampData,
    );
  }
}
