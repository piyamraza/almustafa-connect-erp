import 'dart:convert';

import '../../domain/entities/document_branding_entity.dart';

dynamic principalSignatureImageValue(DocumentBrandingEntity branding) {
  final embedded = branding.principalSignatureData.trim();
  if (embedded.isNotEmpty) {
    try {
      return base64Decode(embedded);
    } catch (_) {
      // Fall back to the legacy URL.
    }
  }
  return branding.principalSignatureUrl;
}

dynamic schoolStampImageValue(DocumentBrandingEntity branding) {
  final embedded = branding.schoolStampData.trim();
  if (embedded.isNotEmpty) {
    try {
      return base64Decode(embedded);
    } catch (_) {
      // Fall back to the legacy URL.
    }
  }
  return branding.schoolStampUrl;
}
