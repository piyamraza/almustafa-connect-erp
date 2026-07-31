$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = (Get-Location).Path
if (-not (Test-Path (Join-Path $projectRoot 'pubspec.yaml'))) {
    throw 'pubspec.yaml not found. Run this script from the almustafa-connect-erp project root.'
}

$pageRelativePath = 'lib/features/timetable/presentation/pages/class_timetable_page.dart'
$pagePath = Join-Path $projectRoot $pageRelativePath
if (-not (Test-Path $pagePath)) {
    throw "Class Timetable page was not found: $pageRelativePath"
}

$pageContent = [System.IO.File]::ReadAllText($pagePath)
$pageContent = $pageContent.Replace("`r`n", "`n")
if (-not $pageContent.Contains('_assignmentsForSubject')) {
    throw 'Teacher assignment matching method was not found in Class Timetable page.'
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$projectParent = Split-Path $projectRoot -Parent
$backupRoot = Join-Path $projectParent "almustafa-connect-erp_backups/teacher_match_fix_$timestamp"
$backupPath = Join-Path $backupRoot $pageRelativePath
New-Item -ItemType Directory -Path (Split-Path $backupPath -Parent) -Force | Out-Null
Copy-Item -Path $pagePath -Destination $backupPath -Force

$replacementMethod = @'
  List<TeacherAssignmentEntity> _assignmentsForSubject(
    AcademicSubjectEntity subject,
  ) {
    final selectedClass = _selectedClass;
    final selectedSection = _selectedSection;
    if (selectedClass == null || selectedSection == null) {
      return const <TeacherAssignmentEntity>[];
    }

    final academicSession = _normalise(_sessionController.text);
    final subjectName = _normalise(subject.name);
    final byTeacher = <String, TeacherAssignmentEntity>{};

    for (final assignment in _assignments) {
      final classMatches = assignment.classId == selectedClass.id ||
          _normalise(assignment.classId) == _normalise(selectedClass.name);
      final sectionMatches = assignment.sectionId == selectedSection.id ||
          _normalise(assignment.sectionId) ==
              _normalise(selectedSection.name);
      final sessionMatches =
          _normalise(assignment.academicSession) == academicSession;
      final subjectMatches =
          _normalise(assignment.subject) == subjectName;

      if (classMatches &&
          sectionMatches &&
          sessionMatches &&
          subjectMatches) {
        byTeacher[assignment.teacherId] = assignment;
      }
    }

    final values = byTeacher.values.toList()
      ..sort(
        (first, second) =>
            first.teacherName.compareTo(second.teacherName),
      );
    return values;
  }

'@

if (-not $pageContent.Contains('final classMatches =')) {
    $methodStartMarker = '  List<TeacherAssignmentEntity> _assignmentsForSubject('
    $nextMethodMarker = '  AcademicClassEntity? get _selectedClass'
    $methodStart = $pageContent.IndexOf($methodStartMarker)
    $methodEnd = $pageContent.IndexOf($nextMethodMarker, $methodStart)

    if ($methodStart -lt 0 -or $methodEnd -lt 0) {
        throw 'Could not safely locate the teacher assignment matching method.'
    }

    $pageContent = $pageContent.Remove(
        $methodStart,
        $methodEnd - $methodStart
    ).Insert($methodStart, $replacementMethod)
}

# PowerShell 5 may decode a UTF-8 bullet incorrectly. Build both patterns by
# Unicode code point so this setup script remains ASCII-compatible.
$mojibakeBullet = [string]([char]0x00E2) +
    [string]([char]0x20AC) +
    [string]([char]0x00A2)
$unicodeBullet = [string]([char]0x2022)
$pageContent = $pageContent.Replace($mojibakeBullet, '-')
$pageContent = $pageContent.Replace($unicodeBullet, '-')

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($pagePath, $pageContent, $utf8NoBom)

Write-Host "Fixed: $pageRelativePath" -ForegroundColor Green
Write-Host 'Teacher matching now supports both saved names and document IDs.' -ForegroundColor Green
Write-Host "Backup location: $backupRoot" -ForegroundColor DarkGray

Write-Host ''
Write-Host 'Running dart format...' -ForegroundColor Cyan
& dart format $pagePath
if ($LASTEXITCODE -ne 0) {
    throw 'dart format failed.'
}

Write-Host ''
Write-Host 'Running flutter analyze...' -ForegroundColor Cyan
& flutter analyze
if ($LASTEXITCODE -ne 0) {
    throw 'flutter analyze found issues. Review the output above.'
}

Write-Host ''
Write-Host 'Teacher assignment matching fix completed successfully.' -ForegroundColor Green
