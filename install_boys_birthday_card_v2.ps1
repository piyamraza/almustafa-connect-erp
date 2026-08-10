$ErrorActionPreference = "Stop"

$root = "D:\Projects\almustafa-connect-erp"
$templatePath = Join-Path $root "lib\features\documents\templates\birthday\birthday_card_template_boy_v2.dart"
$previewPath  = Join-Path $root "lib\features\documents\presentation\pages\birthday_document_preview_page.dart"

$template = @'
import '../../domain/entities/document_element_entity.dart';
import '../../domain/entities/document_element_style.dart';
import '../../domain/entities/document_element_type.dart';
import '../../domain/entities/document_page_entity.dart';
import '../../domain/entities/document_template_category.dart';
import '../../domain/entities/document_template_entity.dart';
import '../../domain/entities/document_type.dart';

DocumentTemplateEntity buildBirthdayCardBoyV2() {
  final now = DateTime.now();

  return DocumentTemplateEntity(
    id: 'birthday_boy_blue_v2',
    name: 'Birthday Boy Blue Premium',
    documentType: DocumentType.birthdayCard,
    category: DocumentTemplateCategory.kids,
    version: 2,
    layoutKey: 'birthday_boy_blue_premium',
    description:
        'Premium blue birthday card for boys with balloons, bunting, gift, school branding and principal signature.',
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
      'theme': 'boy_blue_premium',
      'documentPurpose': 'birthday',
      'gender': 'male',
      'supportsStudentPhoto': false,
    },
    pages: [
      DocumentPageEntity(
        id: 'birthday_boy_page_1',
        width: 1080,
        height: 1528,
        orientation: DocumentPageOrientation.portrait,
        backgroundColor: '#DDEFFF',
        pageNumber: 1,
        elements: const [
          DocumentElementEntity(
            id: 'main_background',
            type: DocumentElementType.shape,
            x: 0, y: 0, width: 1, height: 1, zIndex: 1,
            style: DocumentElementStyle(backgroundColor: '#DDEFFF'),
          ),
          DocumentElementEntity(
            id: 'bottom_band_gold',
            type: DocumentElementType.shape,
            x: 0, y: 0.965, width: 1, height: 0.035, zIndex: 2,
            style: DocumentElementStyle(backgroundColor: '#F2B632'),
          ),
          DocumentElementEntity(
            id: 'bottom_band_blue',
            type: DocumentElementType.shape,
            x: 0, y: 0.972, width: 1, height: 0.028, zIndex: 3,
            style: DocumentElementStyle(backgroundColor: '#073B7A'),
          ),
          DocumentElementEntity(
            id: 'school_logo',
            type: DocumentElementType.schoolLogo,
            x: 0.045, y: 0.025, width: 0.18, height: 0.13, zIndex: 20,
            dataKey: 'branding.schoolLogo',
            style: DocumentElementStyle(
              imageFit: DocumentImageFit.contain,
              shape: DocumentElementShape.circle,
            ),
          ),
          DocumentElementEntity(
            id: 'school_name',
            type: DocumentElementType.text,
            x: 0.245, y: 0.035, width: 0.68, height: 0.075, zIndex: 21,
            staticValue: '{{branding.schoolName}}',
            style: DocumentElementStyle(
              fontSize: 32,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#083B78',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 2,
            ),
          ),
          DocumentElementEntity(
            id: 'school_divider',
            type: DocumentElementType.shape,
            x: 0.28, y: 0.112, width: 0.58, height: 0.0025, zIndex: 21,
            style: DocumentElementStyle(backgroundColor: '#174F91'),
          ),
          DocumentElementEntity(
            id: 'bunting_1', type: DocumentElementType.shape,
            x: 0.02, y: 0.16, width: 0.07, height: 0.035, zIndex: 6,
            style: DocumentElementStyle(backgroundColor: '#0B5AA6'),
          ),
          DocumentElementEntity(
            id: 'bunting_2', type: DocumentElementType.shape,
            x: 0.095, y: 0.16, width: 0.07, height: 0.035, zIndex: 6,
            style: DocumentElementStyle(backgroundColor: '#F5B83D'),
          ),
          DocumentElementEntity(
            id: 'bunting_3', type: DocumentElementType.shape,
            x: 0.17, y: 0.16, width: 0.07, height: 0.035, zIndex: 6,
            style: DocumentElementStyle(backgroundColor: '#164F91'),
          ),
          DocumentElementEntity(
            id: 'bunting_4', type: DocumentElementType.shape,
            x: 0.76, y: 0.16, width: 0.07, height: 0.035, zIndex: 6,
            style: DocumentElementStyle(backgroundColor: '#164F91'),
          ),
          DocumentElementEntity(
            id: 'bunting_5', type: DocumentElementType.shape,
            x: 0.835, y: 0.16, width: 0.07, height: 0.035, zIndex: 6,
            style: DocumentElementStyle(backgroundColor: '#4DA3E6'),
          ),
          DocumentElementEntity(
            id: 'bunting_6', type: DocumentElementType.shape,
            x: 0.91, y: 0.16, width: 0.07, height: 0.035, zIndex: 6,
            style: DocumentElementStyle(backgroundColor: '#F5B83D'),
          ),
          DocumentElementEntity(
            id: 'stars_left',
            type: DocumentElementType.text,
            x: 0.03, y: 0.23, width: 0.18, height: 0.12, zIndex: 7,
            staticValue: '★   ✦\n  ✦   ★',
            style: DocumentElementStyle(
              fontSize: 22,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#0B5AA6',
              textAlignment: DocumentTextAlignment.center,
            ),
          ),
          DocumentElementEntity(
            id: 'stars_right',
            type: DocumentElementType.text,
            x: 0.80, y: 0.24, width: 0.17, height: 0.14, zIndex: 7,
            staticValue: '✦   ★\n ★   ✦',
            style: DocumentElementStyle(
              fontSize: 22,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#E3A41D',
              textAlignment: DocumentTextAlignment.center,
            ),
          ),
          DocumentElementEntity(
            id: 'happy_text',
            type: DocumentElementType.text,
            x: 0.22, y: 0.20, width: 0.56, height: 0.07, zIndex: 15,
            staticValue: 'Happy',
            style: DocumentElementStyle(
              fontSize: 50,
              fontWeight: DocumentFontWeight.medium,
              italic: true,
              textColor: '#073B7A',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),
          DocumentElementEntity(
            id: 'birthday_text',
            type: DocumentElementType.text,
            x: 0.10, y: 0.255, width: 0.80, height: 0.14, zIndex: 15,
            staticValue: 'Birthday!',
            style: DocumentElementStyle(
              fontSize: 82,
              fontWeight: DocumentFontWeight.bold,
              italic: true,
              textColor: '#073B7A',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
            ),
          ),
          DocumentElementEntity(
            id: 'birthday_heart',
            type: DocumentElementType.text,
            x: 0.42, y: 0.385, width: 0.16, height: 0.035, zIndex: 16,
            staticValue: '♥',
            style: DocumentElementStyle(
              fontSize: 27,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#073B7A',
              textAlignment: DocumentTextAlignment.center,
            ),
          ),
          DocumentElementEntity(
            id: 'birthday_message',
            type: DocumentElementType.text,
            x: 0.27, y: 0.43, width: 0.46, height: 0.13, zIndex: 16,
            staticValue:
                'Wishing you a day\nfilled with happiness,\nsuccess and\nwonderful memories.',
            style: DocumentElementStyle(
              fontSize: 24,
              fontWeight: DocumentFontWeight.semiBold,
              textColor: '#123E72',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              lineHeight: 1.35,
              maxLines: 4,
            ),
          ),
          DocumentElementEntity(
            id: 'balloon_blue_1',
            type: DocumentElementType.shape,
            x: 0.015, y: 0.55, width: 0.12, height: 0.09, zIndex: 10,
            style: DocumentElementStyle(
              backgroundColor: '#0869C6',
              shape: DocumentElementShape.circle,
            ),
          ),
          DocumentElementEntity(
            id: 'balloon_blue_2',
            type: DocumentElementType.shape,
            x: 0.075, y: 0.61, width: 0.13, height: 0.095, zIndex: 11,
            style: DocumentElementStyle(
              backgroundColor: '#53A8ED',
              shape: DocumentElementShape.circle,
            ),
          ),
          DocumentElementEntity(
            id: 'balloon_white',
            type: DocumentElementType.shape,
            x: 0.02, y: 0.69, width: 0.14, height: 0.10, zIndex: 10,
            style: DocumentElementStyle(
              backgroundColor: '#F9FCFF',
              borderColor: '#A9CBE8',
              borderWidth: 2,
              shape: DocumentElementShape.circle,
            ),
          ),
          DocumentElementEntity(
            id: 'balloon_string_1',
            type: DocumentElementType.shape,
            x: 0.075, y: 0.635, width: 0.002, height: 0.23, zIndex: 5,
            style: DocumentElementStyle(backgroundColor: '#7AA6CB'),
          ),
          DocumentElementEntity(
            id: 'balloon_string_2',
            type: DocumentElementType.shape,
            x: 0.13, y: 0.70, width: 0.002, height: 0.17, zIndex: 5,
            style: DocumentElementStyle(backgroundColor: '#7AA6CB'),
          ),
          DocumentElementEntity(
            id: 'student_crown',
            type: DocumentElementType.text,
            x: 0.40, y: 0.57, width: 0.20, height: 0.045, zIndex: 17,
            staticValue: '♛',
            style: DocumentElementStyle(
              fontSize: 31,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#D99B12',
              textAlignment: DocumentTextAlignment.center,
            ),
          ),
          DocumentElementEntity(
            id: 'student_name',
            type: DocumentElementType.text,
            x: 0.18, y: 0.61, width: 0.64, height: 0.10, zIndex: 18,
            staticValue: '{{student.name}}',
            style: DocumentElementStyle(
              fontSize: 48,
              fontWeight: DocumentFontWeight.bold,
              italic: true,
              textColor: '#073B7A',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 2,
            ),
          ),
          DocumentElementEntity(
            id: 'student_name_underline',
            type: DocumentElementType.shape,
            x: 0.36, y: 0.715, width: 0.28, height: 0.0025, zIndex: 17,
            style: DocumentElementStyle(backgroundColor: '#D99B12'),
          ),
          DocumentElementEntity(
            id: 'student_class',
            type: DocumentElementType.text,
            x: 0.30, y: 0.725, width: 0.40, height: 0.035, zIndex: 18,
            staticValue: '{{student.classSection}}',
            style: DocumentElementStyle(
              fontSize: 17,
              fontWeight: DocumentFontWeight.medium,
              textColor: '#456B91',
              textAlignment: DocumentTextAlignment.center,
            ),
          ),
          DocumentElementEntity(
            id: 'gift_box',
            type: DocumentElementType.shape,
            x: 0.76, y: 0.70, width: 0.19, height: 0.17, zIndex: 11,
            style: DocumentElementStyle(
              backgroundColor: '#073B7A',
              borderColor: '#E0AA2D',
              borderWidth: 1.5,
              borderRadius: 8,
              shape: DocumentElementShape.roundedRectangle,
            ),
          ),
          DocumentElementEntity(
            id: 'gift_ribbon_vertical',
            type: DocumentElementType.shape,
            x: 0.835, y: 0.70, width: 0.035, height: 0.17, zIndex: 12,
            style: DocumentElementStyle(backgroundColor: '#69B5F1'),
          ),
          DocumentElementEntity(
            id: 'gift_ribbon_horizontal',
            type: DocumentElementType.shape,
            x: 0.76, y: 0.755, width: 0.19, height: 0.028, zIndex: 12,
            style: DocumentElementStyle(backgroundColor: '#69B5F1'),
          ),
          DocumentElementEntity(
            id: 'gift_bow',
            type: DocumentElementType.text,
            x: 0.79, y: 0.655, width: 0.13, height: 0.07, zIndex: 13,
            staticValue: '✦',
            style: DocumentElementStyle(
              fontSize: 52,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#69B5F1',
              textAlignment: DocumentTextAlignment.center,
            ),
          ),
          DocumentElementEntity(
            id: 'principal_signature',
            type: DocumentElementType.principalSignature,
            x: 0.37, y: 0.79, width: 0.26, height: 0.07, zIndex: 20,
            dataKey: 'branding.principalSignature',
            visibleWhenKey: 'branding.principalSignature',
            visibleWhenValue: 'exists',
            style: DocumentElementStyle(imageFit: DocumentImageFit.contain),
          ),
          DocumentElementEntity(
            id: 'principal_signature_line',
            type: DocumentElementType.shape,
            x: 0.38, y: 0.86, width: 0.24, height: 0.0015, zIndex: 19,
            style: DocumentElementStyle(backgroundColor: '#174F91'),
          ),
          DocumentElementEntity(
            id: 'principal_name',
            type: DocumentElementType.text,
            x: 0.35, y: 0.865, width: 0.30, height: 0.035, zIndex: 20,
            staticValue: '{{branding.principalName}}',
            style: DocumentElementStyle(
              fontSize: 20,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#073B7A',
              textAlignment: DocumentTextAlignment.center,
            ),
          ),
          DocumentElementEntity(
            id: 'principal_designation',
            type: DocumentElementType.text,
            x: 0.35, y: 0.90, width: 0.30, height: 0.03, zIndex: 20,
            staticValue: '{{branding.principalDesignation}}',
            style: DocumentElementStyle(
              fontSize: 15,
              textColor: '#385E85',
              textAlignment: DocumentTextAlignment.center,
            ),
          ),
        ],
      ),
    ],
  );
}
'@

New-Item -ItemType Directory -Force -Path (Split-Path $templatePath) | Out-Null
[IO.File]::WriteAllText($templatePath, $template, [Text.UTF8Encoding]::new($false))

$preview = Get-Content $previewPath -Raw -Encoding UTF8

if (-not $preview.Contains("birthday_card_template_boy_v2.dart")) {
  $needle = "import '../../templates/birthday/birthday_card_template_v1.dart';"
  if (-not $preview.Contains($needle)) { throw "Birthday template import not found." }
  $preview = $preview.Replace(
    $needle,
    $needle + "`r`nimport '../../templates/birthday/birthday_card_template_boy_v2.dart';"
  )
}

$preview = $preview.Replace(
  "final template =`r`n        buildBirthdayCardTemplateV1();",
  "final template = _birthdayTemplateFor(widget.person);"
)
$preview = $preview.Replace(
  "final template =`n        buildBirthdayCardTemplateV1();",
  "final template = _birthdayTemplateFor(widget.person);"
)

if (-not $preview.Contains("DocumentTemplateEntity _birthdayTemplateFor(")) {
  $anchor = "  DocumentBrandingEntity _buildBranding("
  if (-not $preview.Contains($anchor)) { throw "Branding method anchor not found." }
  $selector = @"
  DocumentTemplateEntity _birthdayTemplateFor(
    EngagementPersonEntity person,
  ) {
    if (person.isMale) {
      return buildBirthdayCardBoyV2();
    }

    // Dedicated girls template will be added after its design is approved.
    return buildBirthdayCardTemplateV1();
  }

"@
  $preview = $preview.Replace($anchor, $selector + $anchor)
}

[IO.File]::WriteAllText($previewPath, $preview, [Text.UTF8Encoding]::new($false))

Write-Host "DONE - Boys birthday card V2 installed." -ForegroundColor Green
Write-Host "Male students use the new premium blue card." -ForegroundColor Cyan
Write-Host "Female students keep the existing card for now." -ForegroundColor Cyan
Write-Host ""
Write-Host "Run:" -ForegroundColor Yellow
Write-Host "dart format lib/features/documents/templates/birthday/birthday_card_template_boy_v2.dart lib/features/documents/presentation/pages/birthday_document_preview_page.dart"
Write-Host "flutter analyze lib/features/documents/templates/birthday/birthday_card_template_boy_v2.dart lib/features/documents/presentation/pages/birthday_document_preview_page.dart"
