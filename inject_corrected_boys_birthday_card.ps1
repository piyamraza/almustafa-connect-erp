$ErrorActionPreference = "Stop"

$root = "D:\Projects\almustafa-connect-erp"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$assetSource = Join-Path $scriptDir "birthday_card_boy_clean_final.png"
$assetTarget = Join-Path $root "assets\images\birthday_card_boy_clean_final.png"
$templatePath = Join-Path $root "lib\features\documents\templates\birthday\birthday_card_template_boy_v2.dart"
$previewPath = Join-Path $root "lib\features\documents\presentation\pages\birthday_document_preview_page.dart"

if (-not (Test-Path $assetSource)) {
  throw "Missing asset next to script: $assetSource"
}

Copy-Item $templatePath "$templatePath.before_clean_birthday_patch.bak" -Force
Copy-Item $previewPath "$previewPath.before_clean_birthday_patch.bak" -Force

New-Item -ItemType Directory -Force -Path (Split-Path $assetTarget) | Out-Null
Copy-Item $assetSource $assetTarget -Force

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
    id: 'birthday_boy_blue_clean_v3',
    name: 'Birthday Boy Blue Final',
    documentType: DocumentType.birthdayCard,
    category: DocumentTemplateCategory.kids,
    version: 3,
    layoutKey: 'birthday_boy_blue_clean_final',
    description:
        'Approved clean boys birthday artwork with dynamic school branding, wish, student details and principal signature.',
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
      'theme': 'boy_blue_clean_final',
      'documentPurpose': 'birthday',
      'gender': 'male',
      'backgroundAsset': 'assets/images/birthday_card_boy_clean_final.png',
    },
    pages: [
      DocumentPageEntity(
        id: 'birthday_boy_page_1',
        width: 1328,
        height: 1218,
        orientation: DocumentPageOrientation.landscape,
        backgroundColor: '#DCEEFF',
        pageNumber: 1,
        elements: const [
          DocumentElementEntity(
            id: 'approved_clean_artwork',
            type: DocumentElementType.image,
            x: 0,
            y: 0,
            width: 1,
            height: 1,
            zIndex: 1,
            staticValue: 'assets/images/birthday_card_boy_clean_final.png',
            metadata: {'sourceType': 'asset'},
            style: DocumentElementStyle(
              imageFit: DocumentImageFit.fill,
            ),
          ),

          // Dynamic school branding.
          DocumentElementEntity(
            id: 'school_logo',
            type: DocumentElementType.schoolLogo,
            x: 0.055,
            y: 0.035,
            width: 0.13,
            height: 0.13,
            zIndex: 20,
            dataKey: 'branding.schoolLogo',
            style: DocumentElementStyle(
              imageFit: DocumentImageFit.contain,
              shape: DocumentElementShape.circle,
            ),
          ),
          DocumentElementEntity(
            id: 'school_name',
            type: DocumentElementType.text,
            x: 0.20,
            y: 0.045,
            width: 0.60,
            height: 0.08,
            zIndex: 21,
            staticValue: '{{branding.schoolName}}',
            style: DocumentElementStyle(
              fontSize: 30,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#083B78',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 2,
            ),
          ),

          // Dynamic wish message.
          DocumentElementEntity(
            id: 'birthday_message',
            type: DocumentElementType.text,
            x: 0.31,
            y: 0.36,
            width: 0.38,
            height: 0.16,
            zIndex: 22,
            staticValue: '{{birthday.message}}',
            style: DocumentElementStyle(
              fontSize: 22,
              fontWeight: DocumentFontWeight.semiBold,
              textColor: '#123E72',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              lineHeight: 1.35,
              maxLines: 5,
            ),
          ),

          // Dynamic student name + class.
          DocumentElementEntity(
            id: 'student_crown',
            type: DocumentElementType.text,
            x: 0.43,
            y: 0.54,
            width: 0.14,
            height: 0.05,
            zIndex: 23,
            staticValue: '♛',
            style: DocumentElementStyle(
              fontSize: 30,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#D99B12',
              textAlignment: DocumentTextAlignment.center,
            ),
          ),
          DocumentElementEntity(
            id: 'student_name',
            type: DocumentElementType.text,
            x: 0.22,
            y: 0.585,
            width: 0.56,
            height: 0.10,
            zIndex: 23,
            staticValue: '{{student.name}}',
            style: DocumentElementStyle(
              fontSize: 44,
              fontWeight: DocumentFontWeight.bold,
              italic: true,
              textColor: '#073B7A',
              textAlignment: DocumentTextAlignment.center,
              verticalAlignment: DocumentVerticalAlignment.center,
              maxLines: 2,
            ),
          ),
          DocumentElementEntity(
            id: 'student_class',
            type: DocumentElementType.text,
            x: 0.36,
            y: 0.69,
            width: 0.28,
            height: 0.04,
            zIndex: 23,
            staticValue: '{{student.classSection}}',
            style: DocumentElementStyle(
              fontSize: 18,
              fontWeight: DocumentFontWeight.semiBold,
              textColor: '#385E85',
              textAlignment: DocumentTextAlignment.center,
            ),
          ),

          // Dynamic principal signature block.
          DocumentElementEntity(
            id: 'principal_signature',
            type: DocumentElementType.principalSignature,
            x: 0.40,
            y: 0.76,
            width: 0.20,
            height: 0.07,
            zIndex: 24,
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
            x: 0.37,
            y: 0.835,
            width: 0.26,
            height: 0.035,
            zIndex: 24,
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
            x: 0.39,
            y: 0.872,
            width: 0.22,
            height: 0.03,
            zIndex: 24,
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
[System.IO.File]::WriteAllText(
  $templatePath,
  $template,
  [System.Text.UTF8Encoding]::new($false)
)

$preview = Get-Content $previewPath -Raw -Encoding UTF8

# Add editable birthday message controller if not already present.
if (-not $preview.Contains("_birthdayMessageController")) {
  $fieldAnchor = "  bool _exporting = false;"
  if (-not $preview.Contains($fieldAnchor)) {
    throw "Preview patch failed: controller field anchor not found."
  }
  $preview = $preview.Replace(
    $fieldAnchor,
    "  bool _exporting = false;`r`n`r`n  late final TextEditingController _birthdayMessageController;"
  )

  $oldInitCrLf = "  void initState() {`r`n    super.initState();`r`n`r`n    _settingsFuture = sl<GetSchoolSettings>()();`r`n  }"
  $oldInitLf = "  void initState() {`n    super.initState();`n`n    _settingsFuture = sl<GetSchoolSettings>()();`n  }"
  $newInit = @"
  void initState() {
    super.initState();

    _birthdayMessageController = TextEditingController(
      text: 'Wishing you a day filled with happiness, success and wonderful memories.',
    );

    _settingsFuture = sl<GetSchoolSettings>()();
  }

  @override
  void dispose() {
    _birthdayMessageController.dispose();
    super.dispose();
  }
"@

  if ($preview.Contains($oldInitCrLf)) {
    $preview = $preview.Replace($oldInitCrLf, $newInit.TrimEnd())
  } elseif ($preview.Contains($oldInitLf)) {
    $preview = $preview.Replace($oldInitLf, $newInit.TrimEnd())
  } else {
    throw "Preview patch failed: initState pattern not found."
  }
}

# Add message editor under export toolbar if not already there.
if (-not $preview.Contains("Edit Birthday Wish")) {
  $toolbar = @"
        _ExportToolbar(
          busy: _exporting,
          onSavePng: _savePng,
          onSavePdf: _savePdf,
          onPrint: _printPdf,
          onSharePdf: _sharePdf,
          onSharePng: _sharePng,
        ),
"@

  if (-not $preview.Contains($toolbar.TrimEnd())) {
    throw "Preview patch failed: export toolbar anchor not found."
  }

  $editor = @"
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: TextField(
            controller: _birthdayMessageController,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Edit Birthday Wish',
              hintText: 'Write birthday wish message',
              prefixIcon: Icon(Icons.edit_note_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ),
"@

  $preview = $preview.Replace(
    $toolbar.TrimEnd(),
    $toolbar.TrimEnd() + "`r`n" + $editor.TrimEnd()
  )
}

# Use editable text in document data.
$oldMap = "'birthday': {'age': age, 'message': _birthdayMessage(person)}"
if ($preview.Contains($oldMap)) {
  $newMap = @"
'birthday': {
          'age': age,
          'message': _birthdayMessageController.text.trim().isEmpty
              ? _birthdayMessage(person)
              : _birthdayMessageController.text.trim(),
        }
"@
  $preview = $preview.Replace($oldMap, $newMap.Trim())
}

[System.IO.File]::WriteAllText(
  $previewPath,
  $preview,
  [System.Text.UTF8Encoding]::new($false)
)

Write-Host ""
Write-Host "DONE - Correct clean boys birthday card installed." -ForegroundColor Green
Write-Host "No fixed school/student/signature text exists in the background." -ForegroundColor Green
Write-Host "Birthday wish is editable on Preview." -ForegroundColor Green
Write-Host ""
Write-Host "Run:" -ForegroundColor Yellow
Write-Host "flutter pub get"
Write-Host "dart format lib/features/documents/templates/birthday/birthday_card_template_boy_v2.dart lib/features/documents/presentation/pages/birthday_document_preview_page.dart"
Write-Host "flutter analyze lib/features/documents/templates/birthday/birthday_card_template_boy_v2.dart lib/features/documents/presentation/pages/birthday_document_preview_page.dart"
