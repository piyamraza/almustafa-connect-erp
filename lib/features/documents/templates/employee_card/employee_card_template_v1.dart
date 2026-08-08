import '../../domain/entities/document_element_entity.dart';
import '../../domain/entities/document_element_style.dart';
import '../../domain/entities/document_element_type.dart';
import '../../domain/entities/document_page_entity.dart';
import '../../domain/entities/document_template_category.dart';
import '../../domain/entities/document_template_entity.dart';
import '../../domain/entities/document_type.dart';

DocumentTemplateEntity buildEmployeeCardTemplateV1() {
  final now = DateTime.now();

  return DocumentTemplateEntity(
    id: 'employee_card_simple_v1',
    name: 'Employee ID Card Simple',
    documentType: DocumentType.employeeCard,
    category: DocumentTemplateCategory.official,
    version: 1,
    layoutKey: 'employee_card_simple',
    description:
        'Official employee identity card for teaching and non-teaching employees.',
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
      'documentPurpose': 'employee_card',
      'side': 'front',
      'orientation': 'portrait',
    },
    pages: [
      DocumentPageEntity(
        id: 'employee_card_front',
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
            id: 'card_title',
            type: DocumentElementType.text,
            x: 0.30,
            y: 0.135,
            width: 0.60,
            height: 0.04,
            zIndex: 11,
            staticValue: 'EMPLOYEE ID CARD',
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
            id: 'employee_photo',
            type: DocumentElementType.personPhoto,
            x: 0.31,
            y: 0.225,
            width: 0.38,
            height: 0.24,
            zIndex: 15,
            dataKey: 'employee.photo',
            style: DocumentElementStyle(
              imageFit: DocumentImageFit.cover,
              borderColor: '#123A63',
              borderWidth: 2,
              borderRadius: 12,
            ),
          ),

          DocumentElementEntity(
            id: 'employee_name',
            type: DocumentElementType.text,
            x: 0.08,
            y: 0.50,
            width: 0.84,
            height: 0.065,
            zIndex: 16,
            staticValue: '{{employee.name}}',
            style: DocumentElementStyle(
              fontSize: 24,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#123A63',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 2,
            ),
          ),

          DocumentElementEntity(
            id: 'designation',
            type: DocumentElementType.text,
            x: 0.10,
            y: 0.565,
            width: 0.80,
            height: 0.045,
            zIndex: 16,
            staticValue: '{{employee.designation}}',
            style: DocumentElementStyle(
              fontSize: 17,
              fontWeight: DocumentFontWeight.semiBold,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'employee_type',
            type: DocumentElementType.text,
            x: 0.10,
            y: 0.615,
            width: 0.80,
            height: 0.04,
            zIndex: 16,
            staticValue: '{{employee.employeeType}}',
            style: DocumentElementStyle(
              fontSize: 14,
              fontWeight: DocumentFontWeight.medium,
              textColor: '#667085',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'employee_code',
            type: DocumentElementType.text,
            x: 0.10,
            y: 0.675,
            width: 0.80,
            height: 0.045,
            zIndex: 16,
            staticValue: 'Employee ID: {{employee.employeeCode}}',
            style: DocumentElementStyle(
              fontSize: 15,
              fontWeight: DocumentFontWeight.medium,
              textColor: '#344054',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'phone',
            type: DocumentElementType.text,
            x: 0.10,
            y: 0.725,
            width: 0.80,
            height: 0.045,
            zIndex: 16,
            staticValue: 'Phone: {{employee.phone}}',
            style: DocumentElementStyle(
              fontSize: 14,
              fontWeight: DocumentFontWeight.normal,
              textColor: '#475467',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),

          DocumentElementEntity(
            id: 'joining_date',
            type: DocumentElementType.text,
            x: 0.10,
            y: 0.775,
            width: 0.80,
            height: 0.045,
            zIndex: 16,
            staticValue: 'Joining Date: {{employee.joiningDate}}',
            style: DocumentElementStyle(
              fontSize: 14,
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
            y: 0.84,
            width: 0.25,
            height: 0.07,
            zIndex: 20,
            dataKey: 'branding.principalSignature',
            visibleWhenKey: 'branding.principalSignature',
            visibleWhenValue: 'exists',
            style: DocumentElementStyle(
              imageFit: DocumentImageFit.contain,
            ),
          ),

          DocumentElementEntity(
            id: 'principal_label',
            type: DocumentElementType.text,
            x: 0.57,
            y: 0.905,
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
