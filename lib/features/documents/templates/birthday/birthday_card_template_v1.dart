import '../../domain/entities/document_element_entity.dart';
import '../../domain/entities/document_element_style.dart';
import '../../domain/entities/document_element_type.dart';
import '../../domain/entities/document_page_entity.dart';
import '../../domain/entities/document_template_category.dart';
import '../../domain/entities/document_template_entity.dart';
import '../../domain/entities/document_type.dart';

DocumentTemplateEntity buildBirthdayCardTemplateV1() {
  final now = DateTime.now();

  return DocumentTemplateEntity(
    id: 'birthday_kids_blue_v1',
    name: 'Birthday Kids Blue',
    documentType: DocumentType.birthdayCard,
    category: DocumentTemplateCategory.kids,
    version: 1,
    layoutKey: 'birthday_kids_blue',
    description:
        'Kids birthday card template with school branding, student photo and principal signature.',
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
      'theme': 'kids_blue',
      'documentPurpose': 'birthday',
      'supportsStudentPhoto': true,
    },
    pages: [
      DocumentPageEntity(
        id: 'birthday_page_1',
        width: 1080,
        height: 1080,
        orientation: DocumentPageOrientation.square,
        backgroundColor: '#EAF4FF',
        pageNumber: 1,
        elements: const [
          DocumentElementEntity(
            id: 'background_panel',
            type: DocumentElementType.shape,
            x: 0.04,
            y: 0.04,
            width: 0.92,
            height: 0.92,
            zIndex: 1,
            style: DocumentElementStyle(
              backgroundColor: '#FFFFFF',
              borderColor: '#B9D9FF',
              borderWidth: 2,
              borderRadius: 28,
            ),
          ),

          DocumentElementEntity(
            id: 'school_logo',
            type: DocumentElementType.schoolLogo,
            x: 0.08,
            y: 0.07,
            width: 0.14,
            height: 0.14,
            zIndex: 10,
            dataKey: 'branding.schoolLogo',
            style: DocumentElementStyle(
              imageFit: DocumentImageFit.contain,
              shape: DocumentElementShape.roundedRectangle,
              borderRadius: 16,
            ),
          ),

          DocumentElementEntity(
            id: 'school_name',
            type: DocumentElementType.text,
            x: 0.25,
            y: 0.085,
            width: 0.62,
            height: 0.09,
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
            id: 'happy_birthday_title',
            type: DocumentElementType.text,
            x: 0.12,
            y: 0.22,
            width: 0.76,
            height: 0.10,
            zIndex: 12,
            staticValue: 'HAPPY BIRTHDAY',
            style: DocumentElementStyle(
              fontSize: 42,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#0B63CE',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              letterSpacing: 1.2,
            ),
          ),

          DocumentElementEntity(
            id: 'student_photo',
            type: DocumentElementType.personPhoto,
            x: 0.36,
            y: 0.34,
            width: 0.28,
            height: 0.28,
            zIndex: 13,
            dataKey: 'student.photo',
            style: DocumentElementStyle(
              imageFit: DocumentImageFit.cover,
              shape: DocumentElementShape.circle,
              borderColor: '#0B63CE',
              borderWidth: 4,
            ),
          ),

          DocumentElementEntity(
            id: 'student_name',
            type: DocumentElementType.text,
            x: 0.14,
            y: 0.64,
            width: 0.72,
            height: 0.08,
            zIndex: 14,
            staticValue: '{{student.name}}',
            style: DocumentElementStyle(
              fontSize: 34,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#182230',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 2,
            ),
          ),

          DocumentElementEntity(
            id: 'student_class',
            type: DocumentElementType.text,
            x: 0.24,
            y: 0.715,
            width: 0.52,
            height: 0.05,
            zIndex: 14,
            staticValue:
                '{{student.class}} {{student.section}}',
            style: DocumentElementStyle(
              fontSize: 18,
              fontWeight: DocumentFontWeight.medium,
              textColor: '#667085',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 1,
            ),
          ),

          DocumentElementEntity(
            id: 'birthday_message',
            type: DocumentElementType.text,
            x: 0.12,
            y: 0.77,
            width: 0.76,
            height: 0.10,
            zIndex: 14,
            staticValue: '{{birthday.message}}',
            style: DocumentElementStyle(
              fontSize: 19,
              fontWeight: DocumentFontWeight.normal,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              lineHeight: 1.35,
              maxLines: 4,
            ),
          ),

          DocumentElementEntity(
            id: 'principal_signature',
            type: DocumentElementType.principalSignature,
            x: 0.67,
            y: 0.86,
            width: 0.20,
            height: 0.07,
            zIndex: 15,
            dataKey: 'branding.principalSignature',
            visibleWhenKey: 'branding.principalSignature',
            visibleWhenValue: 'exists',
            style: DocumentElementStyle(
              imageFit: DocumentImageFit.contain,
            ),
          ),

          DocumentElementEntity(
            id: 'principal_name',
            type: DocumentElementType.text,
            x: 0.61,
            y: 0.925,
            width: 0.30,
            height: 0.035,
            zIndex: 16,
            staticValue: '{{branding.principalName}}',
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
            x: 0.61,
            y: 0.955,
            width: 0.30,
            height: 0.025,
            zIndex: 16,
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
