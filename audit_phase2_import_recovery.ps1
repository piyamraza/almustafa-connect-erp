[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Full([string]$Path) {
  Join-Path $root $Path
}

$file = 'lib/core/audit/data/services/audit_service_impl.dart'
$full = Full $file

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run this script from the Flutter project root.'
}

if (-not (Test-Path $full)) {
  throw "REQUIRED FILE ERROR: $file"
}

$text = [IO.File]::ReadAllText($full)

$text = $text.Replace(
  "import '../../../features/access_control/domain/entities/app_role_entity.dart';",
  "import '../../../../features/access_control/domain/entities/app_role_entity.dart';"
)

$text = $text.Replace(
  "import '../../../features/access_control/domain/entities/user_role_assignment_entity.dart';",
  "import '../../../../features/access_control/domain/entities/user_role_assignment_entity.dart';"
)

$text = $text.Replace(
  "import '../../../features/access_control/domain/services/access_control_service.dart';",
  "import '../../../../features/access_control/domain/services/access_control_service.dart';"
)

[IO.File]::WriteAllText(
  $full,
  $text.Replace("`r`n", "`n"),
  $utf8
)

& dart format $file

if ($LASTEXITCODE -ne 0) {
  throw 'DART FORMAT ERROR.'
}

& flutter analyze `
  lib/core/audit `
  lib/core/di/service_locator.dart `
  --no-fatal-infos `
  --no-fatal-warnings

if ($LASTEXITCODE -ne 0) {
  throw 'AUDIT PHASE 2 RECOVERY ANALYZE ERROR.'
}

Write-Host ''
Write-Host 'Audit Phase 2 recovery completed successfully.' -ForegroundColor Green
Write-Host 'Corrected access-control import paths in audit_service_impl.dart.' -ForegroundColor Yellow
