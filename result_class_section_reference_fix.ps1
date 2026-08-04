[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\result_class_reference_fix_$stamp"

function Full([string]$Path) { Join-Path $root $Path }

function BackupFile([string]$Path) {
  $source = Full $Path
  if (-not (Test-Path $source)) {
    throw "Required file not found: $Path"
  }

  $target = Join-Path $backup $Path
  New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
  Copy-Item $source $target -Force
}

function SaveText([string]$Path, [string]$Text) {
  [IO.File]::WriteAllText(
    (Full $Path),
    $Text.Replace("`r`n", "`n"),
    $utf8
  )
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'Run this script from the Flutter project root.'
}

$statePath = 'lib/features/exams/presentation/bloc/exam_results_state.dart'
$usecasePath = 'lib/features/exams/domain/usecases/generate_exam_results.dart'

BackupFile $statePath
BackupFile $usecasePath

$state = [IO.File]::ReadAllText((Full $statePath)).Replace("`r`n", "`n")

$oldClasses = @'
  List<ExamSubjectSetupEntity> get availableClasses {
    final byId = <String, ExamSubjectSetupEntity>{};
    for (final setup in subjectSetups.where((setup) => setup.isActive)) {
      byId.putIfAbsent(setup.classId, () => setup);
    }
    final values = byId.values.toList(growable: false);
    values.sort((first, second) => first.className.compareTo(second.className));
    return values;
  }
'@

$newClasses = @'
  List<ExamSubjectSetupEntity> get availableClasses {
    final byName = <String, ExamSubjectSetupEntity>{};

    for (final setup in subjectSetups.where((setup) => setup.isActive)) {
      final key = setup.className.trim().toLowerCase();
      byName.putIfAbsent(key, () => setup);
    }

    final values = byName.values.toList(growable: false);
    values.sort(
      (first, second) => first.className.compareTo(second.className),
    );
    return values;
  }
'@

if (-not $state.Contains($oldClasses)) {
  throw 'availableClasses block not found.'
}
$state = $state.Replace($oldClasses, $newClasses)

$oldSections = @'
  List<ExamSubjectSetupEntity> get availableSections {
    if (selectedClassId == null) return const [];
    final byId = <String, ExamSubjectSetupEntity>{};
    for (final setup in subjectSetups.where(
      (setup) => setup.isActive && setup.classId == selectedClassId,
    )) {
      byId.putIfAbsent(setup.sectionId, () => setup);
    }
    final values = byId.values.toList(growable: false);
    values.sort((first, second) => first.sectionName.compareTo(second.sectionName));
    return values;
  }
'@

$newSections = @'
  List<ExamSubjectSetupEntity> get availableSections {
    if (selectedClassId == null) return const [];

    ExamSubjectSetupEntity? selectedClass;

    for (final setup in subjectSetups) {
      if (setup.classId == selectedClassId) {
        selectedClass = setup;
        break;
      }
    }

    if (selectedClass == null) return const [];

    final selectedClassName =
        selectedClass.className.trim().toLowerCase();
    final byName = <String, ExamSubjectSetupEntity>{};

    for (final setup in subjectSetups.where(
      (setup) =>
          setup.isActive &&
          setup.className.trim().toLowerCase() ==
              selectedClassName,
    )) {
      final key = setup.sectionName.trim().toLowerCase();
      byName.putIfAbsent(key, () => setup);
    }

    final values = byName.values.toList(growable: false);
    values.sort(
      (first, second) =>
          first.sectionName.compareTo(second.sectionName),
    );
    return values;
  }
'@

if (-not $state.Contains($oldSections)) {
  throw 'availableSections block not found.'
}
$state = $state.Replace($oldSections, $newSections)

SaveText $statePath $state

$usecase = [IO.File]::ReadAllText((Full $usecasePath)).Replace("`r`n", "`n")

$oldStudents = @'
      final students =
          await _studentRepository
              .getStudentsByClassAndSection(
        classId: representative.classId,
        sectionId: representative.sectionId,
      );

      for (final student
          in students.where((student) => student.isActive)) {
'@

$newStudents = @'
      var students =
          await _studentRepository
              .getStudentsByClassAndSection(
        classId: representative.classId,
        sectionId: representative.sectionId,
      );

      if (students.isEmpty) {
        final allStudents = await _studentRepository.getStudents();

        final classReferences = <String>{
          representative.classId.trim().toLowerCase(),
          representative.className.trim().toLowerCase(),
        };

        final sectionReferences = <String>{
          representative.sectionId.trim().toLowerCase(),
          representative.sectionName.trim().toLowerCase(),
        };

        students = allStudents
            .where(
              (student) =>
                  classReferences.contains(
                    student.classId.trim().toLowerCase(),
                  ) &&
                  sectionReferences.contains(
                    student.sectionId.trim().toLowerCase(),
                  ),
            )
            .toList(growable: false);
      }

      for (final student
          in students.where((student) => student.isActive)) {
'@

if (-not $usecase.Contains($oldStudents)) {
  throw 'Student loading block not found.'
}
$usecase = $usecase.Replace($oldStudents, $newStudents)

SaveText $usecasePath $usecase

dart format $statePath $usecasePath
if ($LASTEXITCODE -ne 0) {
  throw "FORMAT ERROR. Backup: $backup"
}

flutter analyze lib/features/exams --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) {
  throw "ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Result class/section reference fix completed successfully.' -ForegroundColor Green
Write-Host 'Duplicate class and section labels are removed.' -ForegroundColor Green
Write-Host 'Legacy class/section name references are now supported.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
