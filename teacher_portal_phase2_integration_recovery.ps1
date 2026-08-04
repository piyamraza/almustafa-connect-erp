[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\teacher_portal_phase2_integration_$stamp"

function Full([string]$Path) { Join-Path $root $Path }
function ReadText([string]$Path) { [IO.File]::ReadAllText((Full $Path)) }

function WriteText([string]$Path,[string]$Text) {
  [IO.File]::WriteAllText(
    (Full $Path),
    $Text.Replace("`r`n","`n"),
    $utf8
  )
}

function BackupFile([string]$Path) {
  $source = Full $Path
  if (-not (Test-Path $source)) { return }

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

$teacherDashboard =
  'lib/features/teacher_portal/presentation/pages/teacher_portal_dashboard_page.dart'
$teacherLeavePage =
  'lib/features/teacher_portal/presentation/pages/teacher_leave_duties_page.dart'
$adminDutyPage =
  'lib/features/teacher_portal/presentation/pages/substitute_duty_management_page.dart'
$sidebar =
  'lib/features/dashboard/presentation/widgets/sidebar.dart'

foreach ($path in @(
  $teacherDashboard,
  $teacherLeavePage,
  $adminDutyPage,
  $sidebar
)) {
  if (-not (Test-Path (Full $path))) {
    throw "REQUIRED FILE ERROR: $path"
  }
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
BackupFile $teacherDashboard
BackupFile $sidebar

# Teacher dashboard integration.
$teacherText = ReadText $teacherDashboard

$teacherImport = "import 'teacher_leave_duties_page.dart';"

if (-not $teacherText.Contains($teacherImport)) {
  $importAnchor =
    "import '../../../timetable/presentation/pages/timetable_dashboard_page.dart';"

  if (-not $teacherText.Contains($importAnchor)) {
    throw 'TEACHER DASHBOARD IMPORT ANCHOR ERROR.'
  }

  $teacherText = $teacherText.Replace(
    $importAnchor,
    "$importAnchor`n$teacherImport"
  )
}

if (-not $teacherText.Contains('const TeacherLeaveDutiesPage()')) {
  $menuAnchor = @"
          _tile(
            context,
            Icons.security_outlined,
            'Profile & Security',
"@

  $menuIndex = $teacherText.IndexOf(
    $menuAnchor,
    [StringComparison]::Ordinal
  )

  if ($menuIndex -lt 0) {
    throw 'TEACHER DASHBOARD MENU ANCHOR ERROR.'
  }

  $teacherTile = @"
          _tile(
            context,
            Icons.event_busy_outlined,
            'Leave & Duties',
            const TeacherLeaveDutiesPage(),
          ),
"@

  $teacherText =
    $teacherText.Substring(0,$menuIndex) +
    $teacherTile +
    $teacherText.Substring($menuIndex)
}

WriteText $teacherDashboard $teacherText

# Main admin sidebar integration.
$sidebarText = ReadText $sidebar

$adminImport =
  "import '../../../teacher_portal/presentation/pages/substitute_duty_management_page.dart';"

if (-not $sidebarText.Contains($adminImport)) {
  $importAnchor =
    "import '../../../teachers/presentation/pages/teachers_module_page.dart';"

  if (-not $sidebarText.Contains($importAnchor)) {
    throw 'SIDEBAR IMPORT ANCHOR ERROR.'
  }

  $sidebarText = $sidebarText.Replace(
    $importAnchor,
    "$importAnchor`n$adminImport"
  )
}

if (-not $sidebarText.Contains('const SubstituteDutyManagementPage()')) {
  $tileAnchor = @"
                    if (_access.hasPermission(AppPermission.staffView))
                      _menuTile(
"@

  $tileIndex = $sidebarText.IndexOf(
    $tileAnchor,
    [StringComparison]::Ordinal
  )

  if ($tileIndex -lt 0) {
    throw 'SIDEBAR SUBSTITUTE DUTY TILE ANCHOR ERROR.'
  }

  $adminTile = @"
                    if (_access.hasPermission(AppPermission.staffView))
                      _menuTile(
                        context,
                        icon: Icons.swap_horiz,
                        title: 'Substitute Duties',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.staffView,
                          moduleName: 'Substitute Duties',
                          page: const SubstituteDutyManagementPage(),
                        ),
                      ),
"@

  $sidebarText =
    $sidebarText.Substring(0,$tileIndex) +
    $adminTile +
    $sidebarText.Substring($tileIndex)
}

if (-not $sidebarText.Contains("'Substitute Duties' =>")) {
  $colorAnchor =
    "      'Staff' => const Color(0xFFFBBF24),"

  if (-not $sidebarText.Contains($colorAnchor)) {
    throw 'SIDEBAR SUBSTITUTE DUTY COLOR ANCHOR ERROR.'
  }

  $sidebarText = $sidebarText.Replace(
    $colorAnchor,
    "$colorAnchor`n      'Substitute Duties' => const Color(0xFF0EA5E9),"
  )
}

WriteText $sidebar $sidebarText

& dart format `
  $teacherDashboard `
  $sidebar

if ($LASTEXITCODE -ne 0) {
  throw "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze `
  lib/features/teacher_portal `
  lib/features/dashboard/presentation/widgets/sidebar.dart `
  --no-fatal-infos `
  --no-fatal-warnings

if ($LASTEXITCODE -ne 0) {
  throw "TEACHER PORTAL PHASE 2 INTEGRATION ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Teacher Portal Phase 2 integration completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Teacher menu: Leave & Duties' -ForegroundColor Yellow
Write-Host 'Admin menu: Substitute Duties' -ForegroundColor Yellow
