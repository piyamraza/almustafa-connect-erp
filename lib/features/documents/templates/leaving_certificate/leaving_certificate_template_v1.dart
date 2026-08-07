import '../../domain/entities/document_element_entity.dart';
import '../../domain/entities/document_element_style.dart';
import '../../domain/entities/document_element_type.dart';
import '../../domain/entities/document_page_entity.dart';
import '../../domain/entities/document_template_category.dart';
import '../../domain/entities/document_template_entity.dart';
import '../../domain/entities/document_type.dart';

DocumentTemplateEntity buildLeavingCertificateTemplateV1() {
  final now = DateTime.now();

  return DocumentTemplateEntity(
    id: 'leaving_certificate_official_v1',
    name: 'Leaving Certificate Official',
    documentType: DocumentType.leavingCertificate,
    category: DocumentTemplateCategory.official,
    version: 1,
    layoutKey: 'leaving_certificate_official',
    description:
        'Official leaving certificate with student academic history, leaving details, school branding, principal signature and school stamp.',
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
      'documentPurpose': 'leaving_certificate',
      'paperSize': 'A4',
      'orientation': 'portrait',
    },
    pages: [
      DocumentPageEntity(
        id: 'leaving_certificate_page_1',
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
            y: 0.17,
            width: 0.64,
            height: 0.06,
            zIndex: 12,
            staticValue: 'LEAVING CERTIFICATE',
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
            x: 0.35,
            y: 0.233,
            width: 0.30,
            height: 0.003,
            zIndex: 12,
            style: DocumentElementStyle(
              backgroundColor: '#123A63',
            ),
          ),

          DocumentElementEntity(
            id: 'certificate_number',
            type: DocumentElementType.text,
            x: 0.09,
            y: 0.27,
            width: 0.30,
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
            x: 0.66,
            y: 0.27,
            width: 0.25,
            height: 0.035,
            zIndex: 13,
            staticValue:
                'Issue Date: {{certificate.issueDate}}',
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
            y: 0.325,
            width: 0.80,
            height: 0.05,
            zIndex: 14,
            staticValue:
                'This is to certify that',
            style: DocumentElementStyle(
              fontSize: 17,
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
            y: 0.375,
            width: 0.76,
            height: 0.055,
            zIndex: 15,
            staticValue: '{{student.name}}',
            style: DocumentElementStyle(
              fontSize: 27,
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
            y: 0.435,
            width: 0.74,
            height: 0.04,
            zIndex: 15,
            staticValue:
                'S/O, D/O {{student.fatherName}}',
            style: DocumentElementStyle(
              fontSize: 16,
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
            y: 0.49,
            width: 0.80,
            height: 0.05,
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
            id: 'dob_row',
            type: DocumentElementType.text,
            x: 0.11,
            y: 0.555,
            width: 0.78,
            height: 0.04,
            zIndex: 16,
            staticValue:
                'Date of Birth: {{student.dateOfBirth}}',
            style: DocumentElementStyle(
              fontSize: 15,
              fontWeight: DocumentFontWeight.normal,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.left,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'admission_date_row',
            type: DocumentElementType.text,
            x: 0.11,
            y: 0.60,
            width: 0.78,
            height: 0.04,
            zIndex: 16,
            staticValue:
                'Date of Admission: {{leaving.dateOfAdmission}}',
            style: DocumentElementStyle(
              fontSize: 15,
              fontWeight: DocumentFontWeight.normal,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.left,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'leaving_date_row',
            type: DocumentElementType.text,
            x: 0.11,
            y: 0.645,
            width: 0.78,
            height: 0.04,
            zIndex: 16,
            staticValue:
                'Date of Leaving: {{leaving.dateOfLeaving}}',
            style: DocumentElementStyle(
              fontSize: 15,
              fontWeight: DocumentFontWeight.normal,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.left,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'reason_row',
            type: DocumentElementType.text,
            x: 0.11,
            y: 0.69,
            width: 0.78,
            height: 0.055,
            zIndex: 16,
            staticValue:
                'Reason for Leaving: {{leaving.reason}}',
            style: DocumentElementStyle(
              fontSize: 15,
              fontWeight: DocumentFontWeight.normal,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.left,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 2,
            ),
          ),

          DocumentElementEntity(
            id: 'conduct_row',
            type: DocumentElementType.text,
            x: 0.11,
            y: 0.75,
            width: 0.78,
            height: 0.045,
            zIndex: 16,
            staticValue:
                'Conduct: {{leaving.conduct}}',
            style: DocumentElementStyle(
              fontSize: 15,
              fontWeight: DocumentFontWeight.normal,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.left,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'closing_text',
            type: DocumentElementType.text,
            x: 0.11,
            y: 0.80,
            width: 0.78,
            height: 0.05,
            zIndex: 16,
            staticValue:
                'The student has left the institution with no outstanding academic obligations as per school record.',
            style: DocumentElementStyle(
              fontSize: 15,
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
            y: 0.86,
            width: 0.16,
            height: 0.095,
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
            y: 0.85,
            width: 0.20,
            height: 0.07,
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
            y: 0.915,
            width: 0.28,
            height: 0.03,
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
            y: 0.94,
            width: 0.28,
            height: 0.02,
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
        ],
      ),
    ],
  );
}