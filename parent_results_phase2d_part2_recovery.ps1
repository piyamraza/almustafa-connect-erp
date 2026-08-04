[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\parent_results_phase2d_part2_recovery_$stamp"

function Full([string]$p){Join-Path $root $p}

$page='lib/features/parent_portal/presentation/pages/parent_results_page.dart'
$full=Full $page

if(-not(Test-Path (Full 'pubspec.yaml'))){
  throw 'Run from project root.'
}

if(-not(Test-Path $full)){
  throw "Required file not found: $page"
}

$backupFile=Join-Path $backup $page
New-Item -ItemType Directory -Force -Path (Split-Path $backupFile -Parent)|Out-Null
Copy-Item $full $backupFile -Force

$text=[IO.File]::ReadAllText($full).Replace("`r`n","`n")

$text=$text.Replace(
  'return const ListView(',
  'return ListView('
)

$text=$text.Replace(
  'Icon(item.$3 as IconData)',
  'Icon(item.$3)'
)

$text=$text.Replace(
  'Text(item.$1 as String)',
  'Text(item.$1)'
)

[IO.File]::WriteAllText($full,$text,$utf8)

dart format $page
if($LASTEXITCODE -ne 0){
  throw "FORMAT ERROR. Backup: $backup"
}

flutter analyze lib/features/parent_portal lib/features/exams --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){
  throw "ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Parent Results Phase 2D recovery completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
