$ErrorActionPreference = "Stop"

$root = "D:\Projects\almustafa-connect-erp"
$templatePath = Join-Path $root "lib\features\documents\templates\birthday\birthday_card_template_boy_v2.dart"
$previewPath  = Join-Path $root "lib\features\documents\presentation\pages\birthday_document_preview_page.dart"
$imageRendererPath = Join-Path $root "lib\features\documents\presentation\renderer\renderers\image_renderer.dart"

function Replace-Required {
    param(
        [string]$Text,
        [string]$Old,
        [string]$New,
        [string]$Label
    )
    if (-not $Text.Contains($Old)) {
        throw "Patch failed: pattern not found for $Label"
    }
    return $Text.Replace($Old, $New)
}

Copy-Item $templatePath "$templatePath.before_birthday_adjustments.bak" -Force
Copy-Item $previewPath "$previewPath.before_birthday_adjustments.bak" -Force
Copy-Item $imageRendererPath "$imageRendererPath.before_birthday_export_fix.bak" -Force

# -------------------------
# BOYS TEMPLATE ADJUSTMENTS
# -------------------------
$t = Get-Content $templatePath -Raw -Encoding UTF8

# School logo: larger.
$t = Replace-Required $t `
"            x: 0.055,
            y: 0.035,
            width: 0.13,
            height: 0.13," `
"            x: 0.045,
            y: 0.025,
            width: 0.16,
            height: 0.16," `
"school logo size"

# School name: larger, dark blue.
$t = Replace-Required $t `
"              fontSize: 30,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#083B78'," `
"              fontSize: 38,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#073B7A'," `
"school name style"

# Message: larger.
$t = Replace-Required $t `
"              fontSize: 22,
              fontWeight: DocumentFontWeight.semiBold,
              textColor: '#123E72'," `
"              fontSize: 28,
              fontWeight: DocumentFontWeight.semiBold,
              textColor: '#123E72'," `
"birthday message size"

# Student name: much larger.
$t = Replace-Required $t `
"              fontSize: 44,
              fontWeight: DocumentFontWeight.bold,
              italic: true," `
"              fontSize: 62,
              fontWeight: DocumentFontWeight.bold,
              italic: true," `
"student name size"

# Class label + larger.
$t = Replace-Required $t `
"            staticValue: '{{student.classSection}}'," `
"            staticValue: 'Class: {{student.classSection}}'," `
"class label"

$t = Replace-Required $t `
"              fontSize: 18,
              fontWeight: DocumentFontWeight.semiBold,
              textColor: '#385E85'," `
"              fontSize: 24,
              fontWeight: DocumentFontWeight.bold,
              textColor: '#385E85'," `
"class size"

# Signature: larger and a little higher.
$t = Replace-Required $t `
"            x: 0.40,
            y: 0.76,
            width: 0.20,
            height: 0.07," `
"            x: 0.365,
            y: 0.745,
            width: 0.27,
            height: 0.10," `
"principal signature size"

[System.IO.File]::WriteAllText($templatePath, $t, [System.Text.UTF8Encoding]::new($false))

# -------------------------
# PNG SIZE REDUCTION
# -------------------------
$p = Get-Content $previewPath -Raw -Encoding UTF8

# Standalone PNG + shared PNG: reduce raster scale.
$p = $p.Replace(
"final bytes = await _capturePng(pixelRatio: 3);",
"final bytes = await _capturePng(pixelRatio: 1.8);"
)

# PDF can stay modest.
$p = $p.Replace(
"final pngBytes = await _capturePng(pixelRatio: 1.5);",
"final pngBytes = await _capturePng(pixelRatio: 1.35);"
)

[System.IO.File]::WriteAllText($previewPath, $p, [System.Text.UTF8Encoding]::new($false))

# -------------------------
# EXPORT LOGO/SIGNATURE FIX
# -------------------------
# HTML-backed Image.network can display in Flutter Web preview but is not painted
# into RepaintBoundary screenshots. Switch to normal Flutter network image rendering
# so logo/signature are included in saved PNG/PDF.
$i = Get-Content $imageRendererPath -Raw -Encoding UTF8

$old = @"
    return Image.network(
      source,
      width: double.infinity,
      height: double.infinity,
      fit: fit,

      // Required for Firebase Storage images
      // when documents are rendered in Flutter Web.
      webHtmlElementStrategy:
          WebHtmlElementStrategy.prefer,

      errorBuilder: _errorBuilder,
    );
"@

$new = @"
    return Image.network(
      source,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: _errorBuilder,
    );
"@

if (-not $i.Contains($old.Trim())) {
    throw "Patch failed: Image.network export pattern not found."
}
$i = $i.Replace($old.Trim(), $new.Trim())

[System.IO.File]::WriteAllText($imageRendererPath, $i, [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "DONE - Birthday card adjustments applied." -ForegroundColor Green
Write-Host " - PNG export ratio reduced from 3.0 to 1.8" -ForegroundColor Green
Write-Host " - School logo enlarged" -ForegroundColor Green
Write-Host " - School name enlarged + dark blue" -ForegroundColor Green
Write-Host " - Birthday message enlarged" -ForegroundColor Green
Write-Host " - Student name enlarged" -ForegroundColor Green
Write-Host " - Class label changed to Class: 3-A style" -ForegroundColor Green
Write-Host " - Principal signature enlarged" -ForegroundColor Green
Write-Host " - Network images changed so logo/signature can be captured in export" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Happy Birthday is part of the clean background artwork." -ForegroundColor Yellow
Write-Host "Its vertical position cannot be changed from Dart without changing the background PNG." -ForegroundColor Yellow
Write-Host ""
Write-Host "Run:" -ForegroundColor Cyan
Write-Host "dart format lib/features/documents/templates/birthday/birthday_card_template_boy_v2.dart lib/features/documents/presentation/pages/birthday_document_preview_page.dart lib/features/documents/presentation/renderer/renderers/image_renderer.dart"
Write-Host "flutter analyze lib/features/documents/templates/birthday/birthday_card_template_boy_v2.dart lib/features/documents/presentation/pages/birthday_document_preview_page.dart lib/features/documents/presentation/renderer/renderers/image_renderer.dart"
