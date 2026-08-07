import '../entities/school_branding_entity.dart';

abstract class SchoolBrandingRepository {
  Future<SchoolBrandingEntity?> getBranding();

  Future<void> saveBranding(
    SchoolBrandingEntity branding,
  );

  Future<void> updateSchoolLogo(
    String logoUrl,
  );

  Future<void> updatePrincipalSignature(
    String signatureUrl,
    PrincipalSignatureSource source,
  );

  Future<void> updatePrincipalInformation({
    required String principalName,
    required String principalDesignation,
  });

  Future<void> deleteSchoolLogo();

  Future<void> deletePrincipalSignature();
}
