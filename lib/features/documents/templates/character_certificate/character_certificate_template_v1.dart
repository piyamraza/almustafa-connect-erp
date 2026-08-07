import '../../domain/entities/document_element_entity.dart';
import '../../domain/entities/document_element_style.dart';
import '../../domain/entities/document_element_type.dart';
import '../../domain/entities/document_page_entity.dart';
import '../../domain/entities/document_template_category.dart';
import '../../domain/entities/document_template_entity.dart';
import '../../domain/entities/document_type.dart';

DocumentTemplateEntity buildCharacterCertificateTemplateV1() {
  final now = DateTime.now();

  return DocumentTemplateEntity(
    id: 'character_certificate_official_v1',
    name: 'Character Certificate Official',
    documentType: DocumentType.characterCertificate,
    category: DocumentTemplateCategory.official,
    version: 1,
    layoutKey: 'character_certificate_official',
    description:
        'Official character certificate with school branding, student details, principal signature and school stamp.',
    isDefault: true,
    isActive: true,
    useSchoolLogo: true,
    useSchoolName: true,
    usePrincipalName: true,
    usePrincipalDesignation: true,
    usePrincipalSignature: true,
    useSchoolStamp: true,
    createdAt: now,
    updatedAt: now,
    metadata: const <String, dynamic>{
      'theme': 'official_blue',
      'documentPurpose': 'character_certificate',
      'paperSize': 'A4',
      'orientation': 'portrait',
    },
    pages: [
      DocumentPageEntity(
        id: 'character_certificate_page_1',
        width: 794,
        height: 1123,
        orientation: DocumentPageOrientation.portrait,
        backgroundColor: '#FFFFFF',
        pageNumber: 1,
        elements: const [
          DocumentElementEntity(
            id: 'outer_border',
            type: DocumentElementType.shape,
            x: 0.035,
            y: 0.025,
            width: 0.93,
            height: 0.95,
            zIndex: 1,
            style: DocumentElementStyle(
              backgroundColor: '#FFFFFF',
              borderColor: '#123A63',
              borderWidth: 3,
            ),
          ),

          DocumentElementEntity(
            id: 'inner_border',
            type: DocumentElementType.shape,
            x: 0.048,
            y: 0.037,
            width: 0.904,
            height: 0.926,
            zIndex: 2,
            style: DocumentElementStyle(
              backgroundColor: '#FFFFFF',
              borderColor: '#8FB8DC',
              borderWidth: 1.5,
            ),
          ),

          DocumentElementEntity(
            id: 'school_logo',
            type: DocumentElementType.schoolLogo,
            x: 0.09,
            y: 0.07,
            width: 0.12,
            height: 0.085,
            zIndex: 10,
            dataKey: 'branding.schoolLogo',
            style: DocumentElementStyle(
              imageFit: DocumentImageFit.contain,
            ),
          ),

          DocumentElementEntity(
            id: 'school_name',
            type: DocumentElementType.text,
            x: 0.22,
            y: 0.065,
            width: 0.62,
            height: 0.065,
            zIndex: 11,
            staticValue: '{{branding.schoolName}}',
            style: DocumentElementStyle(
              fontSize: 30,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#123A63',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 2,
            ),
          ),

          DocumentElementEntity(
            id: 'certificate_title',
            type: DocumentElementType.text,
            x: 0.18,
            y: 0.175,
            width: 0.64,
            height: 0.06,
            zIndex: 12,
            staticValue: 'CHARACTER CERTIFICATE',
            style: DocumentElementStyle(
              fontSize: 27,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#182230',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              letterSpacing: 1.1,
            ),
          ),

          DocumentElementEntity(
            id: 'title_underline',
            type: DocumentElementType.shape,
            x: 0.33,
            y: 0.238,
            width: 0.34,
            height: 0.003,
            zIndex: 12,
            style: DocumentElementStyle(
              backgroundColor: '#123A63',
            ),
          ),

          DocumentElementEntity(
            id: 'certificate_number_label',
            type: DocumentElementType.text,
            x: 0.09,
            y: 0.275,
            width: 0.23,
            height: 0.035,
            zIndex: 13,
            staticValue:
                'Certificate No: {{certificate.number}}',
            style: DocumentElementStyle(
              fontSize: 13,
              fontWeight: DocumentFontWeight.medium,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.left,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 1,
            ),
          ),

          DocumentElementEntity(
            id: 'issue_date',
            type: DocumentElementType.text,
            x: 0.68,
            y: 0.275,
            width: 0.23,
            height: 0.035,
            zIndex: 13,
            staticValue:
                'Date: {{certificate.issueDate}}',
            style: DocumentElementStyle(
              fontSize: 13,
              fontWeight: DocumentFontWeight.medium,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.right,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 1,
            ),
          ),

          DocumentElementEntity(
            id: 'intro_text',
            type: DocumentElementType.text,
            x: 0.10,
            y: 0.345,
            width: 0.80,
            height: 0.06,
            zIndex: 14,
            staticValue:
                'This is to certify that',
            style: DocumentElementStyle(
              fontSize: 18,
              fontWeight: DocumentFontWeight.normal,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'student_name',
            type: DocumentElementType.text,
            x: 0.12,
            y: 0.405,
            width: 0.76,
            height: 0.06,
            zIndex: 15,
            staticValue: '{{student.name}}',
            style: DocumentElementStyle(
              fontSize: 28,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#123A63',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 2,
            ),
          ),

          DocumentElementEntity(
            id: 'father_name',
            type: DocumentElementType.text,
            x: 0.13,
            y: 0.475,
            width: 0.74,
            height: 0.045,
            zIndex: 15,
            staticValue:
                'S/O, D/O {{student.fatherName}}',
            style: DocumentElementStyle(
              fontSize: 17,
              fontWeight: DocumentFontWeight.medium,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 1,
            ),
          ),

          DocumentElementEntity(
            id: 'student_details',
            type: DocumentElementType.text,
            x: 0.10,
            y: 0.535,
            width: 0.80,
            height: 0.055,
            zIndex: 15,
            staticValue:
                'Admission No. {{student.admissionNo}}     Class {{student.classSection}}',
            style: DocumentElementStyle(
              fontSize: 15,
              fontWeight: DocumentFontWeight.medium,
              textColor: '#475467',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 2,
            ),
          ),

          DocumentElementEntity(
            id: 'certificate_body',
            type: DocumentElementType.text,
            x: 0.11,
            y: 0.62,
            width: 0.78,
            height: 0.15,
            zIndex: 16,
            staticValue:
                'has been a student of this institution. During the period of study, the student remained disciplined and maintained good conduct. To the best of our knowledge, the student bears a good moral character.',
            style: DocumentElementStyle(
              fontSize: 17,
              fontWeight: DocumentFontWeight.normal,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.justify,
              verticalAlignment: DocumentVerticalAlignment.top,
              lineHeight: 1.45,
              maxLines: 7,
            ),
          ),

          DocumentElementEntity(
            id: 'closing_text',
            type: DocumentElementType.text,
            x: 0.11,
            y: 0.775,
            width: 0.78,
            height: 0.055,
            zIndex: 16,
            staticValue:
                'We wish the student every success in future endeavors.',
            style: DocumentElementStyle(
              fontSize: 16,
              fontWeight: DocumentFontWeight.normal,
              italic: true,
              textColor: '#475467',
              textAlignment: DocumentTextAlignment.left,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 2,
            ),
          ),

          DocumentElementEntity(
            id: 'school_stamp',
            type: DocumentElementType.schoolStamp,
            x: 0.13,
            y: 0.835,
            width: 0.16,
            height: 0.105,
            zIndex: 20,
            dataKey: 'branding.schoolStamp',
            visibleWhenKey: 'branding.schoolStamp',
            visibleWhenValue: 'exists',
            style: DocumentElementStyle(
              imageFit: DocumentImageFit.contain,
            ),
          ),

          DocumentElementEntity(
            id: 'principal_signature',
            type: DocumentElementType.principalSignature,
            x: 0.66,
            y: 0.825,
            width: 0.20,
            height: 0.075,
            zIndex: 20,
            dataKey: 'branding.principalSignature',
            visibleWhenKey:
                'branding.principalSignature',
            visibleWhenValue: 'exists',
            style: DocumentElementStyle(
              imageFit: DocumentImageFit.contain,
            ),
          ),

          DocumentElementEntity(
            id: 'principal_name',
            type: DocumentElementType.text,
            x: 0.62,
            y: 0.898,
            width: 0.28,
            height: 0.035,
            zIndex: 21,
            staticValue:
                '{{branding.principalName}}',
            style: DocumentElementStyle(
              fontSize: 14,
              fontWeight: DocumentFontWeight.semiBold,
              textColor: '#182230',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 1,
            ),
          ),

          DocumentElementEntity(
            id: 'principal_designation',
            type: DocumentElementType.text,
            x: 0.62,
            y: 0.928,
            width: 0.28,
            height: 0.025,
            zIndex: 21,
            staticValue:
                '{{branding.principalDesignation}}',
            style: DocumentElementStyle(
              fontSize: 12,
              fontWeight: DocumentFontWeight.normal,
              textColor: '#667085',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 1,
            ),
          ),

          DocumentElementEntity(
            id: 'stamp_label',
            type: DocumentElementType.text,
            x: 0.11,
            y: 0.935,
            width: 0.22,
            height: 0.025,
            zIndex: 21,
            staticValue: 'School Stamp',
            style: DocumentElementStyle(
              fontSize: 11,
              fontWeight: DocumentFontWeight.medium,
              textColor: '#667085',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),
        ],
      ),
    ],
  );
}
