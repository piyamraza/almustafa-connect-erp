import '../../domain/entities/document_element_entity.dart';
import '../../domain/entities/document_element_style.dart';
import '../../domain/entities/document_element_type.dart';
import '../../domain/entities/document_page_entity.dart';
import '../../domain/entities/document_template_category.dart';
import '../../domain/entities/document_template_entity.dart';
import '../../domain/entities/document_type.dart';

DocumentTemplateEntity buildFeeChallanTemplateV1({
  int copyCount = 3,
}) {
  final now = DateTime.now();

  final count = copyCount < 1
      ? 1
      : copyCount > 3
          ? 3
          : copyCount;

  final labels = switch (count) {
    1 => const ['PARENT COPY'],
    2 => const ['SCHOOL COPY', 'PARENT COPY'],
    _ => const ['BANK COPY', 'SCHOOL COPY', 'PARENT COPY'],
  };

  const margin = 0.02;
  const gap = 0.012;

  final columnWidth =
      (1 - (margin * 2) - (gap * (count - 1))) / count;

  final elements = <DocumentElementEntity>[];

  for (var index = 0; index < count; index++) {
    final x =
        margin + index * (columnWidth + gap);

    elements.addAll(
      _buildFeeCopy(
        prefix: 'copy_${index + 1}',
        x: x,
        width: columnWidth,
        copyLabel: labels[index],
      ),
    );
  }

  return DocumentTemplateEntity(
    id: 'fee_challan_official_v1',
    name: 'Fee Challan Official',
    documentType: DocumentType.feeChallan,
    category: DocumentTemplateCategory.official,
    version: 1,
    layoutKey: 'fee_challan_official',
    description:
        'Official school fee challan with configurable bank, school and parent copies.',
    isDefault: true,
    isActive: true,
    useSchoolLogo: true,
    useSchoolName: true,
    usePrincipalName: false,
    usePrincipalDesignation: false,
    usePrincipalSignature: false,
    useSchoolStamp: true,
    createdAt: now,
    updatedAt: now,
    metadata: {
      'theme': 'official_blue',
      'documentPurpose': 'fee_challan',
      'paperSize': 'A4',
      'orientation': 'landscape',
      'copyCount': count,
    },
    pages: [
      DocumentPageEntity(
        id: 'fee_challan_page_1',
        width: 1123,
        height: 794,
        orientation: DocumentPageOrientation.landscape,
        backgroundColor: '#FFFFFF',
        pageNumber: 1,
        elements: elements,
      ),
    ],
  );
}

List<DocumentElementEntity> _buildFeeCopy({
  required String prefix,
  required double x,
  required double width,
  required String copyLabel,
}) {
  final innerX = x + width * 0.04;
  final innerWidth = width * 0.92;

  return [
    DocumentElementEntity(
      id: '${prefix}_border',
      type: DocumentElementType.shape,
      x: x,
      y: 0.025,
      width: width,
      height: 0.95,
      zIndex: 1,
      style: const DocumentElementStyle(
        backgroundColor: '#FFFFFF',
        borderColor: '#123A63',
        borderWidth: 2,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_header',
      type: DocumentElementType.shape,
      x: x,
      y: 0.025,
      width: width,
      height: 0.13,
      zIndex: 2,
      style: const DocumentElementStyle(
        backgroundColor: '#123A63',
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_logo',
      type: DocumentElementType.schoolLogo,
      x: innerX,
      y: 0.045,
      width: width * 0.18,
      height: 0.075,
      zIndex: 10,
      dataKey: 'branding.schoolLogo',
      style: const DocumentElementStyle(
        imageFit: DocumentImageFit.contain,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_school_name',
      type: DocumentElementType.text,
      x: x + width * 0.24,
      y: 0.043,
      width: width * 0.70,
      height: 0.055,
      zIndex: 11,
      staticValue: '{{branding.schoolName}}',
      style: const DocumentElementStyle(
        fontSize: 18,
        fontWeight: DocumentFontWeight.bold,
        textColor: '#FFFFFF',
        textAlignment: DocumentTextAlignment.center,
        verticalAlignment: DocumentVerticalAlignment.center,
        maxLines: 2,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_title',
      type: DocumentElementType.text,
      x: x + width * 0.24,
      y: 0.10,
      width: width * 0.70,
      height: 0.03,
      zIndex: 11,
      staticValue: 'FEE CHALLAN',
      style: const DocumentElementStyle(
        fontSize: 12,
        fontWeight: DocumentFontWeight.semiBold,
        textColor: '#D9EAF7',
        textAlignment: DocumentTextAlignment.center,
        verticalAlignment: DocumentVerticalAlignment.center,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_copy_label',
      type: DocumentElementType.text,
      x: innerX,
      y: 0.165,
      width: innerWidth,
      height: 0.035,
      zIndex: 12,
      staticValue: copyLabel,
      style: const DocumentElementStyle(
        fontSize: 12,
        fontWeight: DocumentFontWeight.bold,
        textColor: '#123A63',
        textAlignment: DocumentTextAlignment.center,
        verticalAlignment: DocumentVerticalAlignment.center,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_challan_no',
      type: DocumentElementType.text,
      x: innerX,
      y: 0.205,
      width: innerWidth,
      height: 0.03,
      zIndex: 12,
      staticValue:
          'Challan No: {{fee.challanNumber}}',
      style: const DocumentElementStyle(
        fontSize: 10,
        fontWeight: DocumentFontWeight.medium,
        textColor: '#344054',
        textAlignment: DocumentTextAlignment.left,
        verticalAlignment: DocumentVerticalAlignment.center,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_student',
      type: DocumentElementType.text,
      x: innerX,
      y: 0.245,
      width: innerWidth,
      height: 0.04,
      zIndex: 13,
      staticValue:
          'Student: {{student.name}}',
      style: const DocumentElementStyle(
        fontSize: 11,
        fontWeight: DocumentFontWeight.semiBold,
        textColor: '#182230',
        textAlignment: DocumentTextAlignment.left,
        verticalAlignment: DocumentVerticalAlignment.center,
        maxLines: 1,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_admission',
      type: DocumentElementType.text,
      x: innerX,
      y: 0.285,
      width: innerWidth,
      height: 0.035,
      zIndex: 13,
      staticValue:
          'Admission No: {{student.admissionNo}}',
      style: const DocumentElementStyle(
        fontSize: 10,
        fontWeight: DocumentFontWeight.normal,
        textColor: '#344054',
        textAlignment: DocumentTextAlignment.left,
        verticalAlignment: DocumentVerticalAlignment.center,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_class',
      type: DocumentElementType.text,
      x: innerX,
      y: 0.32,
      width: innerWidth,
      height: 0.035,
      zIndex: 13,
      staticValue:
          'Class / Section: {{student.classSection}}',
      style: const DocumentElementStyle(
        fontSize: 10,
        fontWeight: DocumentFontWeight.normal,
        textColor: '#344054',
        textAlignment: DocumentTextAlignment.left,
        verticalAlignment: DocumentVerticalAlignment.center,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_session',
      type: DocumentElementType.text,
      x: innerX,
      y: 0.355,
      width: innerWidth,
      height: 0.035,
      zIndex: 13,
      staticValue:
          'Session: {{fee.academicSession}}',
      style: const DocumentElementStyle(
        fontSize: 10,
        fontWeight: DocumentFontWeight.normal,
        textColor: '#344054',
        textAlignment: DocumentTextAlignment.left,
        verticalAlignment: DocumentVerticalAlignment.center,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_months',
      type: DocumentElementType.text,
      x: innerX,
      y: 0.39,
      width: innerWidth,
      height: 0.035,
      zIndex: 13,
      staticValue:
          'Month(s): {{fee.months}}',
      style: const DocumentElementStyle(
        fontSize: 10,
        fontWeight: DocumentFontWeight.medium,
        textColor: '#344054',
        textAlignment: DocumentTextAlignment.left,
        verticalAlignment: DocumentVerticalAlignment.center,
        maxLines: 2,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_due_date',
      type: DocumentElementType.text,
      x: innerX,
      y: 0.425,
      width: innerWidth,
      height: 0.035,
      zIndex: 13,
      staticValue:
          'Due Date: {{fee.dueDate}}',
      style: const DocumentElementStyle(
        fontSize: 10,
        fontWeight: DocumentFontWeight.medium,
        textColor: '#344054',
        textAlignment: DocumentTextAlignment.left,
        verticalAlignment: DocumentVerticalAlignment.center,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_fee_header',
      type: DocumentElementType.text,
      x: innerX,
      y: 0.475,
      width: innerWidth,
      height: 0.035,
      zIndex: 14,
      staticValue: 'FEE DETAILS',
      style: const DocumentElementStyle(
        fontSize: 11,
        fontWeight: DocumentFontWeight.bold,
        textColor: '#FFFFFF',
        backgroundColor: '#123A63',
        textAlignment: DocumentTextAlignment.center,
        verticalAlignment: DocumentVerticalAlignment.center,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_fee_lines',
      type: DocumentElementType.text,
      x: innerX,
      y: 0.515,
      width: innerWidth,
      height: 0.235,
      zIndex: 14,
      staticValue:
          'Tuition Fee: {{fee.tuitionFee}}\n'
          'Transport Fee: {{fee.transportFee}}\n'
          'Other Charges: {{fee.otherCharges}}\n'
          'Previous Arrears: {{fee.previousArrears}}\n'
          'Discount / Scholarship: {{fee.totalDiscount}}\n'
          'Advance Adjustment: {{fee.advanceAdjustment}}\n'
          'Already Paid: {{fee.paidAmount}}',
      style: const DocumentElementStyle(
        fontSize: 10,
        fontWeight: DocumentFontWeight.normal,
        textColor: '#344054',
        textAlignment: DocumentTextAlignment.left,
        verticalAlignment: DocumentVerticalAlignment.top,
        maxLines: 10,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_net_payable',
      type: DocumentElementType.text,
      x: innerX,
      y: 0.755,
      width: innerWidth,
      height: 0.05,
      zIndex: 15,
      staticValue:
          'NET PAYABLE: Rs. {{fee.netPayable}}',
      style: const DocumentElementStyle(
        fontSize: 14,
        fontWeight: DocumentFontWeight.bold,
        textColor: '#123A63',
        textAlignment: DocumentTextAlignment.center,
        verticalAlignment: DocumentVerticalAlignment.center,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_outstanding',
      type: DocumentElementType.text,
      x: innerX,
      y: 0.805,
      width: innerWidth,
      height: 0.04,
      zIndex: 15,
      staticValue:
          'Outstanding: Rs. {{fee.outstanding}}',
      style: const DocumentElementStyle(
        fontSize: 11,
        fontWeight: DocumentFontWeight.semiBold,
        textColor: '#344054',
        textAlignment: DocumentTextAlignment.center,
        verticalAlignment: DocumentVerticalAlignment.center,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_status',
      type: DocumentElementType.text,
      x: innerX,
      y: 0.845,
      width: innerWidth,
      height: 0.035,
      zIndex: 15,
      staticValue:
          'Status: {{fee.status}}',
      style: const DocumentElementStyle(
        fontSize: 10,
        fontWeight: DocumentFontWeight.medium,
        textColor: '#475467',
        textAlignment: DocumentTextAlignment.center,
        verticalAlignment: DocumentVerticalAlignment.center,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_stamp',
      type: DocumentElementType.schoolStamp,
      x: innerX,
      y: 0.885,
      width: width * 0.20,
      height: 0.06,
      zIndex: 20,
      dataKey: 'branding.schoolStamp',
      visibleWhenKey: 'branding.schoolStamp',
      visibleWhenValue: 'exists',
      style: const DocumentElementStyle(
        imageFit: DocumentImageFit.contain,
      ),
    ),
    DocumentElementEntity(
      id: '${prefix}_accounts',
      type: DocumentElementType.text,
      x: x + width * 0.56,
      y: 0.91,
      width: width * 0.36,
      height: 0.03,
      zIndex: 20,
      staticValue: 'Accounts Signature',
      style: const DocumentElementStyle(
        fontSize: 9,
        fontWeight: DocumentFontWeight.medium,
        textColor: '#475467',
        textAlignment: DocumentTextAlignment.center,
        verticalAlignment: DocumentVerticalAlignment.center,
      ),
    ),
  ];
}
