[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\exam_component_compile_recovery_$stamp"

function Full([string]$p){Join-Path $root $p}

function BackupFile([string]$p){
  $source=Full $p
  if(-not(Test-Path $source)){throw "Required file not found: $p"}
  $target=Join-Path $backup $p
  New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent)|Out-Null
  Copy-Item $source $target -Force
}

function WriteText([string]$p,[string]$text){
  [IO.File]::WriteAllText((Full $p),$text.Replace("`r`n","`n"),$utf8)
}

if(-not(Test-Path (Full 'pubspec.yaml'))){
  throw 'Run this script from project root.'
}

$file='lib/features/academic_structure/domain/services/subject_component_exam_service.dart'
BackupFile $file

$text=[IO.File]::ReadAllText((Full $file)).Replace("`r`n","`n")

$text=$text.Replace("import '../entities/subject_entity.dart';`n",'')
$text=$text.Replace('  SubjectEntity? _resolveParentSubject({','  dynamic _resolveParentSubject({')
$text=$text.Replace('    required List<SubjectEntity> subjects,','    required List<dynamic> subjects,')
$text=$text.Replace('    required Map<String, SubjectEntity> subjectsById,','    required Map<String, dynamic> subjectsById,')

WriteText $file $text

dart format $file
if($LASTEXITCODE -ne 0){
  throw "FORMAT ERROR. Backup: $backup"
}

flutter analyze lib/features/exams lib/features/academic_structure --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){
  throw "ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Compile error fixed successfully.' -ForegroundColor Green
Write-Host 'Subject component legacy-name fallback remains enabled.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
