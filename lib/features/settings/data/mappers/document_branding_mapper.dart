import '../../../documents/domain/entities/document_branding_entity.dart';
import '../../domain/entities/school_settings_entity.dart';

class DocumentBrandingMapper {
  const DocumentBrandingMapper._();

  static DocumentBrandingEntity fromSchoolSettings(
    SchoolSettingsEntity settings,
  ) {
    return DocumentBrandingEntity(
      schoolName: settings.schoolName,
      schoolLogoUrl: settings.logoUrl,
      principalName: settings.principalName,
      principalDesignation:
          settings.principalDesignation,
      principalSignatureUrl:
          settings.principalSignatureUrl,
      schoolStampUrl:
          settings.schoolStampUrl,
    );
  }

  static Map<String, dynamic> toPlaceholderValues(
    SchoolSettingsEntity settings,
  ) {
    return {
      'branding': {
        'schoolName': settings.schoolName,
        'schoolLogo': settings.logoUrl,
        'principalName':
            settings.principalName,
        'principalDesignation':
            settings.principalDesignation,
        'principalSignature':
            settings.principalSignatureUrl,
        'schoolStamp':
            settings.schoolStampUrl,
      },
    };
  }
}
