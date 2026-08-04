[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\fee_collection_student_filter_fix_$stamp"

function Full([string]$p){Join-Path $root $p}

function BackupFile([string]$p){
  $s=Full $p
  if(-not(Test-Path $s)){throw "Required file not found: $p"}
  $d=Join-Path $backup $p
  New-Item -ItemType Directory -Force -Path (Split-Path $d -Parent)|Out-Null
  Copy-Item $s $d -Force
}

function WriteText([string]$p,[string]$t){
  [IO.File]::WriteAllText(
    (Full $p),
    $t.Replace("`r`n","`n"),
    $utf8
  )
}

if(-not(Test-Path (Full 'pubspec.yaml'))){
  throw 'Run this script from project root.'
}

$page='lib/features/fees/presentation/pages/fee_collection_page.dart'
BackupFile $page

$text=[IO.File]::ReadAllText((Full $page)).Replace("`r`n","`n")

$oldSearch=@'
    SectionEntity? studentSection;
    for (final item in _sections) {
      if (_academicResolver.sameSection(item.id, student.sectionId) &&
          (studentClass == null || item.classId == studentClass.id)) {
        studentSection = item;
        break;
      }
    }
'@

$newSearch=@'
    SectionEntity? studentSection;
    final normalizedStudentSection =
        AcademicReferenceResolver.normalize(student.sectionId);

    for (final item in _sections) {
      final belongsToSelectedClass =
          studentClass == null || item.classId == studentClass.id;
      final sectionMatches =
          AcademicReferenceResolver.normalize(item.id) ==
              normalizedStudentSection ||
          AcademicReferenceResolver.normalize(item.name) ==
              normalizedStudentSection;

      if (belongsToSelectedClass && sectionMatches) {
        studentSection = item;
        break;
      }
    }
'@

if(-not $text.Contains($oldSearch)){
  throw 'Student search section-resolution block not found.'
}
$text=$text.Replace($oldSearch,$newSearch)

$oldMatches=@'
  bool _matchesSection(StudentEntity student) {
    final selected = _selectedSection;
    if (selected == null) return false;

    return _academicResolver.sameSection(student.sectionId, selected.id);
  }
'@

$newMatches=@'
  bool _matchesSection(StudentEntity student) {
    final selectedClass = _selectedClass;
    final selectedSection = _selectedSection;

    if (selectedClass == null || selectedSection == null) {
      return false;
    }

    if (!_academicResolver.sameClass(student.classId, selectedClass.id)) {
      return false;
    }

    final studentSection =
        AcademicReferenceResolver.normalize(student.sectionId);
    final selectedSectionId =
        AcademicReferenceResolver.normalize(selectedSection.id);
    final selectedSectionName =
        AcademicReferenceResolver.normalize(selectedSection.name);

    return studentSection == selectedSectionId ||
        studentSection == selectedSectionName;
  }
'@

if(-not $text.Contains($oldMatches)){
  throw 'Section matching block not found.'
}
$text=$text.Replace($oldMatches,$newMatches)

WriteText $page $text

dart format $page
if($LASTEXITCODE -ne 0){
  throw "FORMAT ERROR. Backup: $backup"
}

flutter analyze lib/features/fees lib/features/academic_structure lib/features/students --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){
  throw "ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Fee Collection student filter fixed successfully.' -ForegroundColor Green
Write-Host 'Class + Section sidebar now supports both document IDs and legacy names.' -ForegroundColor Green
Write-Host 'Global student search remains unchanged.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
