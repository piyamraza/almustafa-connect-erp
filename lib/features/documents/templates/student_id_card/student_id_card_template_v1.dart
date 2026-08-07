import '../../domain/entities/document_element_entity.dart';
import '../../domain/entities/document_element_style.dart';
import '../../domain/entities/document_element_type.dart';
import '../../domain/entities/document_page_entity.dart';
import '../../domain/entities/document_template_category.dart';
import '../../domain/entities/document_template_entity.dart';
import '../../domain/entities/document_type.dart';

DocumentTemplateEntity buildStudentIdCardTemplateV1() {
  final now = DateTime.now();

  return DocumentTemplateEntity(
    id: 'student_id_card_simple_v1',
    name: 'Student ID Card Simple',
    documentType: DocumentType.idCard,
    category: DocumentTemplateCategory.official,
    version: 1,
    layoutKey: 'student_id_card_simple',
    description:
        'Simple front-only student identity card with school branding and student information.',
    isDefault: true,
    isActive: true,
    useSchoolLogo: true,
    useSchoolName: true,
    usePrincipalName: true,
    usePrincipalDesignation: true,
    usePrincipalSignature: true,
    useSchoolStamp: false,
    createdAt: now,
    updatedAt: now,
    metadata: const <String, dynamic>{
      'theme': 'school_blue',
      'documentPurpose': 'student_id_card',
      'side': 'front',
      'orientation': 'portrait',
    },
    pages: [
      DocumentPageEntity(
        id: 'student_id_card_front',
        width: 540,
        height: 856,
        orientation: DocumentPageOrientation.portrait,
        backgroundColor: '#FFFFFF',
        pageNumber: 1,
        elements: const [
          DocumentElementEntity(
            id: 'card_background',
            type: DocumentElementType.shape,
            x: 0.02,
            y: 0.015,
            width: 0.96,
            height: 0.97,
            zIndex: 1,
            style: DocumentElementStyle(
              backgroundColor: '#FFFFFF',
              borderColor: '#123A63',
              borderWidth: 3,
            ),
          ),

          DocumentElementEntity(
            id: 'header_background',
            type: DocumentElementType.shape,
            x: 0.02,
            y: 0.015,
            width: 0.96,
            height: 0.19,
            zIndex: 2,
            style: DocumentElementStyle(
              backgroundColor: '#123A63',
            ),
          ),

          DocumentElementEntity(
            id: 'school_logo',
            type: DocumentElementType.schoolLogo,
            x: 0.07,
            y: 0.045,
            width: 0.18,
            height: 0.12,
            zIndex: 10,
            dataKey: 'branding.schoolLogo',
            style: DocumentElementStyle(
              imageFit: DocumentImageFit.contain,
            ),
          ),

          DocumentElementEntity(
            id: 'school_name',
            type: DocumentElementType.text,
            x: 0.27,
            y: 0.045,
            width: 0.65,
            height: 0.085,
            zIndex: 11,
            staticValue: '{{branding.schoolName}}',
            style: DocumentElementStyle(
              fontSize: 23,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#FFFFFF',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 2,
            ),
          ),

          DocumentElementEntity(
            id: 'id_card_title',
            type: DocumentElementType.text,
            x: 0.30,
            y: 0.135,
            width: 0.60,
            height: 0.04,
            zIndex: 11,
            staticValue: 'STUDENT ID CARD',
            style: DocumentElementStyle(
              fontSize: 13,
              fontWeight: DocumentFontWeight.medium,
              textColor: '#D9EAF7',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              letterSpacing: 1.2,
            ),
          ),

          DocumentElementEntity(
            id: 'student_photo',
            type: DocumentElementType.personPhoto,
            x: 0.31,
            y: 0.235,
            width: 0.38,
            height: 0.24,
            zIndex: 15,
            dataKey: 'student.photo',
            style: DocumentElementStyle(
              imageFit: DocumentImageFit.cover,
              borderColor: '#123A63',
              borderWidth: 2,
              borderRadius: 12,
            ),
          ),

          DocumentElementEntity(
            id: 'student_name',
            type: DocumentElementType.text,
            x: 0.08,
            y: 0.50,
            width: 0.84,
            height: 0.065,
            zIndex: 16,
            staticValue: '{{student.name}}',
            style: DocumentElementStyle(
              fontSize: 25,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#123A63',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 2,
            ),
          ),

          DocumentElementEntity(
            id: 'admission_number',
            type: DocumentElementType.text,
            x: 0.10,
            y: 0.595,
            width: 0.80,
            height: 0.045,
            zIndex: 16,
            staticValue:
                'Admission No: {{student.admissionNo}}',
            style: DocumentElementStyle(
              fontSize: 16,
              fontWeight: DocumentFontWeight.medium,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'class_section',
            type: DocumentElementType.text,
            x: 0.10,
            y: 0.645,
            width: 0.80,
            height: 0.045,
            zIndex: 16,
            staticValue:
                'Class: {{student.classSection}}',
            style: DocumentElementStyle(
              fontSize: 16,
              fontWeight: DocumentFontWeight.medium,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'roll_number',
            type: DocumentElementType.text,
            x: 0.10,
            y: 0.695,
            width: 0.80,
            height: 0.045,
            zIndex: 16,
            staticValue:
                'Roll No: {{student.rollNumber}}',
            style: DocumentElementStyle(
              fontSize: 15,
              fontWeight: DocumentFontWeight.normal,
              textColor: '#475467',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'date_of_birth',
            type: DocumentElementType.text,
            x: 0.10,
            y: 0.745,
            width: 0.80,
            height: 0.045,
            zIndex: 16,
            staticValue:
                'DOB: {{student.dateOfBirth}}',
            style: DocumentElementStyle(
              fontSize: 15,
              fontWeight: DocumentFontWeight.normal,
              textColor: '#475467',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'principal_signature',
            type: DocumentElementType.principalSignature,
            x: 0.60,
            y: 0.825,
            width: 0.25,
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
            id: 'principal_label',
            type: DocumentElementType.text,
            x: 0.57,
            y: 0.90,
            width: 0.31,
            height: 0.035,
            zIndex: 21,
            staticValue: 'Principal',
            style: DocumentElementStyle(
              fontSize: 12,
              fontWeight: DocumentFontWeight.medium,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'footer_strip',
            type: DocumentElementType.shape,
            x: 0.02,
            y: 0.95,
            width: 0.96,
            height: 0.035,
            zIndex: 5,
            style: DocumentElementStyle(
              backgroundColor: '#123A63',
            ),
          ),
        ],
      ),
    ],
  );
}