[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\settings_phase5_recovery_$stamp"

function Full([string]$p) { Join-Path $root $p }
function ReadText([string]$p) { [IO.File]::ReadAllText((Full $p)) }
function WriteText([string]$p,[string]$t) {
  [IO.File]::WriteAllText((Full $p),$t.Replace("`r`n","`n"),$utf8)
}
function BackupFile([string]$p) {
  $s = Full $p
  if (-not (Test-Path $s)) { return }
  $t = Join-Path $backup $p
  $d = Split-Path $t -Parent
  if (-not (Test-Path $d)) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
  }
  Copy-Item $s $t -Force
}
function InsertBefore([string]$p,[string]$a,[string]$v) {
  $t = ReadText $p
  if ($t.Contains($v.Trim())) { return }
  $i = $t.IndexOf($a,[StringComparison]::Ordinal)
  if ($i -lt 0) { throw "ANCHOR ERROR in $p : $a" }
  BackupFile $p
  WriteText $p ($t.Substring(0,$i)+$v+$t.Substring($i))
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run from Flutter project root.'
}

$required = @(
  'lib/features/settings/data/datasources/system_health_remote_datasource.dart',
  'lib/features/settings/data/repositories/system_health_repository_impl.dart',
  'lib/features/settings/domain/repositories/system_health_repository.dart',
  'lib/features/settings/domain/usecases/manage_system_health.dart',
  'lib/features/settings/presentation/bloc/system_health_bloc.dart',
  'lib/features/settings/presentation/pages/system_health_page.dart',
  'lib/features/settings/presentation/pages/settings_dashboard_page.dart',
  'lib/core/di/service_locator.dart',
  'lib/core/constants/firestore_paths.dart'
)

foreach ($p in $required) {
  if (-not (Test-Path (Full $p))) {
    throw "REQUIRED FILE ERROR: $p"
  }
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($p in $required) { BackupFile $p }

# Fix incorrect Firestore path name.
$healthFile = 'lib/features/settings/data/datasources/system_health_remote_datasource.dart'
$healthText = ReadText $healthFile
$healthText = $healthText.Replace(
  'FirestorePaths.results,',
  'FirestorePaths.examResults,'
)
WriteText $healthFile $healthText

# Add service locator imports.
$sl = 'lib/core/di/service_locator.dart'
$slText = ReadText $sl

$imports = @"
import '../../features/settings/data/datasources/system_health_remote_datasource.dart';
import '../../features/settings/data/repositories/system_health_repository_impl.dart';
import '../../features/settings/domain/repositories/system_health_repository.dart';
import '../../features/settings/domain/usecases/manage_system_health.dart';
import '../../features/settings/presentation/bloc/system_health_bloc.dart';
"@

if (-not $slText.Contains('system_health_remote_datasource.dart')) {
  InsertBefore `
    $sl `
    "import '../../features/settings/data/datasources/settings_remote_datasource.dart';" `
    $imports
}

# Add service locator registrations.
$slText = ReadText $sl

$registrations = @"
  sl.registerLazySingleton<SystemHealthRemoteDataSource>(
    () => SystemHealthRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
      sl<FirebaseAuth>(),
    ),
  );
  sl.registerLazySingleton<SystemHealthRepository>(
    () => SystemHealthRepositoryImpl(
      sl<SystemHealthRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<CheckSystemHealth>(
    () => CheckSystemHealth(
      sl<SystemHealthRepository>(),
    ),
  );
  sl.registerFactory<SystemHealthBloc>(
    () => SystemHealthBloc(
      sl<CheckSystemHealth>(),
    ),
  );

"@

if (-not $slText.Contains('sl.registerLazySingleton<SystemHealthRepository>')) {
  InsertBefore `
    $sl `
    '  sl.registerLazySingleton<SettingsRemoteDataSource>(' `
    $registrations
}

# Integrate System Health page into Settings dashboard.
$page = 'lib/features/settings/presentation/pages/settings_dashboard_page.dart'
$pageText = ReadText $page

if (-not $pageText.Contains("import 'system_health_page.dart';")) {
  $anchor = "import 'security_sessions_page.dart';"
  if (-not $pageText.Contains($anchor)) {
    throw 'SETTINGS PAGE IMPORT ANCHOR ERROR.'
  }
  WriteText $page (
    $pageText.Replace(
      $anchor,
      "$anchor`nimport 'system_health_page.dart';"
    )
  )
}

$pageText = ReadText $page

if (-not $pageText.Contains('const SystemHealthPage()')) {
  $anchor = "label: const Text('Security and Sessions'),"
  $index = $pageText.IndexOf(
    $anchor,
    [StringComparison]::Ordinal
  )

  if ($index -lt 0) {
    throw 'SETTINGS SYSTEM HEALTH BUTTON ANCHOR ERROR.'
  }

  $buttonEnd = $pageText.IndexOf(
    "`n                ),",
    $index,
    [StringComparison]::Ordinal
  )

  if ($buttonEnd -lt 0) {
    throw 'SETTINGS SECURITY BUTTON END ERROR.'
  }

  $insertAt = $buttonEnd + 20

  $button = @"
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const SystemHealthPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.monitor_heart_outlined,
                    ),
                    label: const Text(
                      'System Health and Diagnostics',
                    ),
                  ),
                ),
"@

  WriteText $page (
    $pageText.Substring(0,$insertAt) +
    $button +
    $pageText.Substring($insertAt)
  )
}

& dart format `
  lib/features/settings `
  lib/core/di/service_locator.dart `
  lib/core/constants/firestore_paths.dart

if ($LASTEXITCODE -ne 0) {
  throw "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze `
  lib/features/settings `
  --no-fatal-infos `
  --no-fatal-warnings

if ($LASTEXITCODE -ne 0) {
  throw "SETTINGS ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Settings Phase 5 recovery completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Functional ERP development is now complete.' -ForegroundColor Green
