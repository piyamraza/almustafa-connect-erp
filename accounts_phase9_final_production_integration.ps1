[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\accounts_phase9_$stamp"

function Full([string]$Path) {
  Join-Path $root $Path
}

function Fail([string]$Message) {
  throw $Message
}

function ReadUtf8([string]$Path) {
  [IO.File]::ReadAllText((Full $Path))
}

function WriteUtf8([string]$Path,[string]$Text) {
  $full = Full $Path
  $directory = Split-Path $full -Parent

  if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
  }

  [IO.File]::WriteAllText(
    $full,
    $Text.Replace("`r`n","`n"),
    $utf8
  )
}

function BackupFile([string]$Path) {
  $source = Full $Path
  if (-not (Test-Path $source)) {
    return
  }

  $target = Join-Path $backup $Path
  $directory = Split-Path $target -Parent

  if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
  }

  Copy-Item $source $target -Force
}

function ReplaceOnce(
  [string]$Path,
  [string]$Anchor,
  [string]$Replacement
) {
  $text = ReadUtf8 $Path
  $first = $text.IndexOf($Anchor,[StringComparison]::Ordinal)

  if ($first -lt 0) {
    Fail "ANCHOR ERROR: Anchor was not found in $Path.`n$Anchor"
  }

  $second = $text.IndexOf(
    $Anchor,
    $first + $Anchor.Length,
    [StringComparison]::Ordinal
  )

  if ($second -ge 0) {
    Fail "ANCHOR ERROR: Anchor is ambiguous in $Path.`n$Anchor"
  }

  BackupFile $Path

  WriteUtf8 $Path (
    $text.Substring(0,$first) +
    $Replacement +
    $text.Substring($first + $Anchor.Length)
  )
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  Fail 'PROJECT ROOT ERROR: Run from the Flutter project root.'
}

$sidebar = 'lib/features/dashboard/presentation/widgets/sidebar.dart'
$rules = 'firestore.rules'
$serviceLocator = 'lib/core/di/service_locator.dart'
$accountsDashboard = 'lib/features/accounts/presentation/pages/accounts_dashboard_page.dart'

foreach ($path in @(
  $sidebar,
  $rules,
  $serviceLocator,
  $accountsDashboard
)) {
  if (-not (Test-Path (Full $path))) {
    Fail "REQUIRED FILE ERROR: $path was not found."
  }
}

$serviceText = ReadUtf8 $serviceLocator
foreach ($anchor in @(
  'sl.registerFactory<AccountsBloc>',
  'sl.registerFactory<ExpenseBloc>',
  'sl.registerFactory<PayrollBloc>',
  'sl.registerFactory<IncomeBloc>',
  'sl.registerFactory<ProfitLossBloc>',
  'sl.registerFactory<CashbookBloc>',
  'sl.registerFactory<AccountsReportsBloc>'
)) {
  if (-not $serviceText.Contains($anchor)) {
    Fail "SERVICE LOCATOR ERROR: '$anchor' was not found."
  }
}

$sidebarText = ReadUtf8 $sidebar

if (-not $sidebarText.Contains(
  "import '../../../accounts/presentation/pages/accounts_dashboard_page.dart';"
)) {
  $importAnchor = "import '../../../academic_calendar/presentation/pages/academic_calendar_page.dart';"
  $importReplacement = @"
import '../../../accounts/presentation/pages/accounts_dashboard_page.dart';
$importAnchor
"@
  ReplaceOnce $sidebar $importAnchor $importReplacement
}

$sidebarText = ReadUtf8 $sidebar

if (-not $sidebarText.Contains("title: 'Accounts & Payroll'")) {
  $menuAnchor = @"
                    if (_access.hasPermission(AppPermission.reportsView))
                      _menuTile(
                        context,
                        icon: Icons.assessment,
                        title: 'Reports',
"@

  $menuReplacement = @"
                    if (_access.hasPermission(AppPermission.reportsView))
                      _menuTile(
                        context,
                        icon: Icons.account_balance_outlined,
                        title: 'Accounts & Payroll',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.reportsView,
                          moduleName: 'Accounts & Payroll',
                          page: const AccountsDashboardPage(),
                        ),
                      ),
$menuAnchor
"@

  ReplaceOnce $sidebar $menuAnchor $menuReplacement
}

$sidebarText = ReadUtf8 $sidebar

if (-not $sidebarText.Contains(
  "'Accounts & Payroll' => const Color(0xFF0F766E),"
)) {
  $colorAnchor = "      'Reports' => const Color(0xFF60A5FA),"
  $colorReplacement = @"
      'Accounts & Payroll' => const Color(0xFF0F766E),
$colorAnchor
"@
  ReplaceOnce $sidebar $colorAnchor $colorReplacement
}

$rulesText = ReadUtf8 $rules

if (-not $rulesText.Contains('match /expense_categories/{document=**}')) {
  $rulesAnchor = @"
    // -----------------------------------------------------------------
    // Exams, date sheets and results
    // -----------------------------------------------------------------
"@

  $rulesReplacement = @"
    // -----------------------------------------------------------------
    // Accounts and payroll
    // -----------------------------------------------------------------

    match /expense_categories/{document=**} {
      allow read: if hasAnyPermission('reportsView', 'reportsExport');
      allow write: if hasPermission('reportsExport');
    }

    match /expenses/{document=**} {
      allow read: if hasAnyPermission('reportsView', 'reportsExport');
      allow write: if hasPermission('reportsExport');
    }

    match /income_entries/{document=**} {
      allow read: if hasAnyPermission('reportsView', 'reportsExport');
      allow write: if hasPermission('reportsExport');
    }

    match /payroll_profiles/{document=**} {
      allow read: if hasAnyPermission('reportsView', 'reportsExport');
      allow write: if hasPermission('reportsExport');
    }

    match /payroll_records/{document=**} {
      allow read: if hasAnyPermission('reportsView', 'reportsExport');
      allow write: if hasPermission('reportsExport');
    }

    match /monthly_profit_loss/{document=**} {
      allow read: if hasAnyPermission('reportsView', 'reportsExport');
      allow write: if hasPermission('reportsExport');
    }

    match /cashbook_entries/{document=**} {
      allow read: if hasAnyPermission('reportsView', 'reportsExport');
      allow write: if hasPermission('reportsExport');
    }

$rulesAnchor
"@

  ReplaceOnce $rules $rulesAnchor $rulesReplacement
}

$checklistBytes = [Convert]::FromBase64String('IyBBY2NvdW50cyBNb2R1bGUgUHJvZHVjdGlvbiBWYWxpZGF0aW9uCgojIyBJbnRlZ3JhdGlvbgotIEFjY291bnRzICYgUGF5cm9sbCBhcHBlYXJzIGluIHRoZSBtYWluIHNpZGViYXIgZm9yIHVzZXJzIHdpdGggYHJlcG9ydHNWaWV3YC4KLSBVbmF1dGhvcml6ZWQgdXNlcnMgY2Fubm90IG9wZW4gdGhlIG1vZHVsZS4KLSBBbGwgQWNjb3VudHMgQkxvQ3MgYW5kIHVzZSBjYXNlcyByZXNvbHZlIHRocm91Z2ggR2V0SXQuCi0gRXhwZW5zZXMsIFBheXJvbGwsIEluY29tZSwgUHJvZml0ICYgTG9zcywgQ2FzaGJvb2ssIGFuZCBSZXBvcnRzIHBhZ2VzIG9wZW4gc3VjY2Vzc2Z1bGx5LgoKIyMgRmlyZXN0b3JlIFNlY3VyaXR5Ci0gUmVhZCBhY2Nlc3MgdG8gQWNjb3VudHMgY29sbGVjdGlvbnMgcmVxdWlyZXMgYHJlcG9ydHNWaWV3YCBvciBgcmVwb3J0c0V4cG9ydGAuCi0gV3JpdGUgYWNjZXNzIHJlcXVpcmVzIGByZXBvcnRzRXhwb3J0YC4KLSBTdXBlciBhZG1pbmlzdHJhdG9ycyByZXRhaW4gYWNjZXNzIHRocm91Z2ggYHJvbGVzTWFuYWdlYC4KLSBEZXBsb3kgYGZpcmVzdG9yZS5ydWxlc2AgYWZ0ZXIgdmVyaWZpY2F0aW9uLgoKIyMgRnVuY3Rpb25hbCBWYWxpZGF0aW9uCi0gQ3JlYXRlIGFuZCBhcHByb3ZlIGFuIGV4cGVuc2UsIHRoZW4gbWFyayBpdCBwYWlkLgotIENyZWF0ZSBhIHBheXJvbGwgcHJvZmlsZSwgZ2VuZXJhdGUgcGF5cm9sbCwgYXBwcm92ZSBpdCwgYW5kIG1hcmsgaXQgcGFpZC4KLSBTeW5jIGZlZSBpbmNvbWUgYW5kIGNvbmZpcm0gZHVwbGljYXRlIHByb3RlY3Rpb24uCi0gR2VuZXJhdGUgbW9udGhseSBwcm9maXQgYW5kIGxvc3MuCi0gU3luYyB0aGUgY2FzaGJvb2sgYW5kIGNvbmZpcm0gcnVubmluZyBiYWxhbmNlLgotIEV4cG9ydCBvbmUgUERGIGFuZCBvbmUgRXhjZWwgcmVwb3J0LgotIFZlcmlmeSBkYXNoYm9hcmQgS1BJcyBhbmQgcmVjZW50IHRyYW5zYWN0aW9ucy4KCiMjIFJlbGVhc2UgQ29tbWFuZHMKYGBgcG93ZXJzaGVsbApkYXJ0IGZvcm1hdCBsaWIKZmx1dHRlciBhbmFseXplIC0tbm8tZmF0YWwtaW5mb3MgLS1uby1mYXRhbC13YXJuaW5ncwpmbHV0dGVyIHRlc3QKZmlyZWJhc2UgZGVwbG95IC0tb25seSBmaXJlc3RvcmU6cnVsZXMKYGBgCg==')
$checklistText = [Text.Encoding]::UTF8.GetString($checklistBytes)
WriteUtf8 'docs/accounts/ACCOUNTS_PRODUCTION_VALIDATION.md' $checklistText

& dart format lib/features/accounts lib/features/dashboard/presentation/widgets/sidebar.dart lib/core/di/service_locator.dart

if ($LASTEXITCODE -ne 0) {
  Fail "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze --no-fatal-infos --no-fatal-warnings

if ($LASTEXITCODE -ne 0) {
  Write-Host 'Project analyze contains errors outside Accounts integration. Checking targeted files...' -ForegroundColor Yellow

  & flutter analyze lib/features/accounts lib/features/dashboard/presentation/widgets/sidebar.dart lib/core/di/service_locator.dart --no-fatal-infos --no-fatal-warnings

  if ($LASTEXITCODE -ne 0) {
    Fail "TARGETED ANALYZE ERROR. Backup: $backup"
  }
}

Write-Host ''
Write-Host 'Accounts Phase 9 final production integration completed.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'IMPORTANT: Deploy updated Firestore rules before production use:' -ForegroundColor Yellow
Write-Host 'firebase deploy --only firestore:rules' -ForegroundColor Cyan
