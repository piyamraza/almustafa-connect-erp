$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
    throw 'Run this script from the almustafa-connect-erp project root.'
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$parentDashboard = 'lib/features/parent_portal/presentation/pages/parent_portal_dashboard_page.dart'

function Read-ProjectFile {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $path = Join-Path $root $RelativePath
    if (-not (Test-Path $path)) {
        throw "Required file not found: $RelativePath"
    }

    return [IO.File]::ReadAllText($path).Replace("`r`n", "`n")
}

function Write-ProjectFile {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $path = Join-Path $root $RelativePath
    [IO.File]::WriteAllText($path, $Content, $utf8)
    Write-Host "Updated: $RelativePath" -ForegroundColor Green
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups/parent_portal_phase3_repair_$stamp"
$backupFile = Join-Path $backupRoot $parentDashboard

New-Item -ItemType Directory -Path (Split-Path $backupFile -Parent) -Force | Out-Null
Copy-Item (Join-Path $root $parentDashboard) $backupFile -Force

$content = Read-ProjectFile -RelativePath $parentDashboard

# =========================================================
# 1. Add Parent Communication dashboard import
# =========================================================

$communicationImport = "import 'parent_communication_dashboard_page.dart';"

if (-not $content.Contains($communicationImport)) {
    $importMatches = [regex]::Matches(
        $content,
        "(?m)^import\s+['""].+?['""];\s*$"
    )

    if ($importMatches.Count -eq 0) {
        throw 'Import block not found in Parent Portal dashboard.'
    }

    $lastImport = $importMatches[$importMatches.Count - 1]
    $content = $content.Insert(
        $lastImport.Index + $lastImport.Length,
        "`n$communicationImport"
    )
}

# =========================================================
# 2. Ensure _PortalModulesGrid receives parent
# =========================================================

$content = $content.Replace(
    'const _PortalModulesGrid({required this.student});',
    'const _PortalModulesGrid({required this.parent, required this.student});'
)

if ($content.Contains(
    'class _PortalModulesGrid extends StatelessWidget {'
) -and
    -not $content.Contains(
        "final ParentAccountEntity parent;`n  final StudentEntity student;"
    )) {
    $classPattern = '(?ms)(class _PortalModulesGrid extends StatelessWidget \{\s*const _PortalModulesGrid\([^;]+;\s*)(final StudentEntity student;)'

    if ([regex]::IsMatch($content, $classPattern)) {
        $content = [regex]::Replace(
            $content,
            $classPattern,
            '$1final ParentAccountEntity parent;' + "`n  " + '$2',
            1
        )
    }
}

# Replace common constructor call forms.
$callPatterns = @(
    '(?ms)_PortalModulesGrid\(\s*student:\s*selectedStudent!\s*,?\s*\)',
    '(?ms)_PortalModulesGrid\(\s*student:\s*selectedStudent\s*,?\s*\)'
)

foreach ($pattern in $callPatterns) {
    if ([regex]::IsMatch($content, $pattern)) {
        $content = [regex]::Replace(
            $content,
            $pattern,
            "_PortalModulesGrid(`n            parent: widget.parent,`n            student: selectedStudent!,`n          )",
            1
        )
        break
    }
}

# =========================================================
# 3. Add Phase 3 navigation before fallback SnackBar
# =========================================================

if (-not $content.Contains('ParentCommunicationDashboardPage(')) {
    $fallbackPattern = @'
(?ms)
(\s*)
ScaffoldMessenger\.of\(context\)\.showSnackBar\(
\s*SnackBar\(
\s*content:\s*Text\(
\s*'\$\{module\.\$1\} integration will be connected '
\s*'in Parent Portal Phase [34]\.',
\s*\),
\s*\),
\s*\);
'@

    $match = [regex]::Match(
        $content,
        $fallbackPattern,
        [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace
    )

    if (-not $match.Success) {
        # More tolerant fallback: locate the final ScaffoldMessenger block
        # inside the module card onTap.
        $fallbackPattern2 = '(?ms)(\s*)ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\(\s*''\$\{module\.\$1\} integration will be connected ''\s*''in Parent Portal Phase \d\.''\s*,?\s*\),\s*\),\s*\);'
        $match = [regex]::Match($content, $fallbackPattern2)
    }

    if (-not $match.Success) {
        throw 'Could not locate Parent Portal module fallback action.'
    }

    $indent = $match.Groups[1].Value

    $replacement = @"
${indent}if ([
${indent}  'Fee Status',
${indent}  'Academic Calendar',
${indent}  'Notices',
${indent}].contains(module.`$1)) {
${indent}  Navigator.of(context).push<void>(
${indent}    MaterialPageRoute<void>(
${indent}      builder: (_) =>
${indent}          ParentCommunicationDashboardPage(
${indent}        parent: parent,
${indent}        student: student,
${indent}      ),
${indent}    ),
${indent}  );
${indent}  return;
${indent}}

${indent}ScaffoldMessenger.of(context).showSnackBar(
${indent}  SnackBar(
${indent}    content: Text(
${indent}      '`${module.`$1} integration will be connected '
${indent}      'in Parent Portal Phase 4.',
${indent}    ),
${indent}  ),
${indent});
"@

    $content = $content.Remove($match.Index, $match.Length)
    $content = $content.Insert($match.Index, $replacement)
}

# =========================================================
# 4. Safety verification
# =========================================================

if (-not $content.Contains('ParentCommunicationDashboardPage(')) {
    throw 'Parent Communication dashboard navigation was not added.'
}

if (-not $content.Contains('final ParentAccountEntity parent;')) {
    throw '_PortalModulesGrid parent field was not added.'
}

if (-not $content.Contains('parent: widget.parent')) {
    throw '_PortalModulesGrid parent constructor argument was not added.'
}

Write-ProjectFile -RelativePath $parentDashboard -Content $content

Write-Host ''
Write-Host 'Running flutter pub get...' -ForegroundColor Cyan

& flutter pub get

if ($LASTEXITCODE -ne 0) {
    throw 'flutter pub get failed.'
}

Write-Host ''
Write-Host 'Running dart format...' -ForegroundColor Cyan

& dart format `
    $parentDashboard `
    'lib/features/parent_portal' `
    'lib/core/di/service_locator.dart'

if ($LASTEXITCODE -ne 0) {
    throw 'dart format failed.'
}

Write-Host ''
Write-Host 'Running flutter analyze...' -ForegroundColor Cyan

& flutter analyze

if ($LASTEXITCODE -ne 0) {
    throw 'flutter analyze found issues. Copy the complete output into ChatGPT.'
}

Write-Host ''
Write-Host 'Parent Portal Phase 3 repair completed successfully.' -ForegroundColor Green
Write-Host 'Fees, Notices and Academic Calendar cards are now connected.' -ForegroundColor Cyan
Write-Host "Backup: $backupRoot" -ForegroundColor DarkGray
