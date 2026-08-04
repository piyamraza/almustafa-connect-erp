[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\exam_component_display_name_fix_$stamp"

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

$old='subjectName: component.componentName,'
$new='subjectName: _componentDisplayName(parent.name, component.componentName),'

if(-not $text.Contains($old)){
  throw 'Component subject-name assignment not found.'
}

$text=$text.Replace($old,$new)

$anchor='  static String _normalize(String value) {'
$helper=@'
  static String _componentDisplayName(
    String parentName,
    String componentName,
  ) {
    final cleanParent = parentName.trim();
    final cleanComponent = componentName.trim();

    if (cleanParent.isEmpty) return cleanComponent;
    if (cleanComponent.isEmpty) return cleanParent;

    final normalizedParent = _normalize(cleanParent);
    final normalizedComponent = _normalize(cleanComponent);

    if (normalizedComponent == normalizedParent ||
        normalizedComponent.startsWith('$normalizedParent ')) {
      return cleanComponent;
    }

    return '$cleanParent $cleanComponent';
  }

'@

if(-not $text.Contains('_componentDisplayName(') -or
   $text.IndexOf('_componentDisplayName(') -eq $text.IndexOf($new.Substring($new.IndexOf('_componentDisplayName')))){
  if(-not $text.Contains($anchor)){
    throw 'Helper insertion anchor not found.'
  }
  $text=$text.Replace($anchor,$helper+$anchor)
}

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
Write-Host 'Exam component display names fixed successfully.' -ForegroundColor Green
Write-Host 'Examples: A -> English A, B -> Urdu B, while English A remains English A.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
