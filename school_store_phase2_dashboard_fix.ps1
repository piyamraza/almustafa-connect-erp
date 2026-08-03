[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\school_store_phase2_dashboard_fix_$stamp"

function Full([string]$Path) { Join-Path $root $Path }
function ReadUtf8([string]$Path) { [IO.File]::ReadAllText((Full $Path)) }
function WriteUtf8([string]$Path,[string]$Text) {
  [IO.File]::WriteAllText(
    (Full $Path),
    $Text.Replace("`r`n","`n"),
    $utf8
  )
}
function BackupFile([string]$Path) {
  $source = Full $Path
  $target = Join-Path $backup $Path
  $dir = Split-Path $target -Parent

  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }

  Copy-Item $source $target -Force
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run from Flutter project root.'
}

$dashboard = 'lib/features/school_store/presentation/pages/school_store_dashboard_page.dart'
$serviceLocator = 'lib/core/di/service_locator.dart'

foreach ($path in @($dashboard, $serviceLocator)) {
  if (-not (Test-Path (Full $path))) {
    throw "REQUIRED FILE ERROR: $path"
  }
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
BackupFile $dashboard
BackupFile $serviceLocator

# Confirm Phase 2 service locator integration exists.
$slText = ReadUtf8 $serviceLocator

$requiredRegistrations = @(
  'StorePurchaseRemoteDataSource',
  'StorePurchaseRepository',
  'StorePurchaseBloc'
)

foreach ($name in $requiredRegistrations) {
  if (-not $slText.Contains($name)) {
    throw "SERVICE LOCATOR ERROR: $name integration is missing."
  }
}

$text = ReadUtf8 $dashboard

if (-not $text.Contains("import 'store_purchases_page.dart';")) {
  $anchor = "import '../bloc/school_store_state.dart';"

  if (-not $text.Contains($anchor)) {
    throw 'DASHBOARD IMPORT ANCHOR ERROR.'
  }

  $text = $text.Replace(
    $anchor,
    "$anchor`nimport 'store_purchases_page.dart';"
  )
}

if (-not $text.Contains('const StorePurchasesPage()')) {
  $anchor = @"
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
"@

  $index = $text.IndexOf(
    $anchor,
    [StringComparison]::Ordinal
  )

  if ($index -lt 0) {
    throw 'DASHBOARD CONTENT ANCHOR ERROR.'
  }

  $wrapEndAnchor = @"
              ],
            ),
"@

  $wrapEnd = $text.IndexOf(
    $wrapEndAnchor,
    $index,
    [StringComparison]::Ordinal
  )

  if ($wrapEnd -lt 0) {
    throw 'DASHBOARD SUMMARY WRAP END ERROR.'
  }

  $insertAt = $wrapEnd + $wrapEndAnchor.Length

  $button = @"
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(c).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const StorePurchasesPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.local_shipping_outlined,
                ),
                label: const Text(
                  'Suppliers & Purchases',
                ),
              ),
            ),
"@

  $text = $text.Substring(0,$insertAt) +
      $button +
      $text.Substring($insertAt)
}

# Repair encoding artefacts already visible in the dashboard.
$text = $text.Replace('Ã¢â‚¬Â¢', '-')
$text = $text.Replace('â€¢', '-')

WriteUtf8 $dashboard $text

& dart format $dashboard $serviceLocator

if ($LASTEXITCODE -ne 0) {
  throw "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze `
  lib/features/school_store `
  --no-fatal-infos `
  --no-fatal-warnings

if ($LASTEXITCODE -ne 0) {
  throw "SCHOOL STORE ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'School Store Phase 2 dashboard integration completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
