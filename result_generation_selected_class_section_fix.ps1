[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\result_generation_filter_fix_$stamp"

function Full([string]$Path) {
  Join-Path $root $Path
}

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

$blocPath = 'lib/features/exams/presentation/bloc/exam_results_bloc.dart'
$usecasePath = 'lib/features/exams/domain/usecases/generate_exam_results.dart'

BackupFile $blocPath
BackupFile $usecasePath

$bloc = [IO.File]::ReadAllText((Full $blocPath)).Replace("`r`n", "`n")

$oldExamCheck = @'
    final actorId = event.actorId.trim();
'@

$newExamCheck = @'
    final classId = current.selectedClassId;
    final sectionId = current.selectedSectionId;

    if (classId == null || classId.trim().isEmpty) {
      emit(
        current.copyWith(
          errorMessage: 'Select a class before generating results.',
          clearMessages: true,
        ),
      );
      return;
    }

    if (sectionId == null || sectionId.trim().isEmpty) {
      emit(
        current.copyWith(
          errorMessage: 'Select a section before generating results.',
          clearMessages: true,
        ),
      );
      return;
    }

    final actorId = event.actorId.trim();
'@

if (-not $bloc.Contains($oldExamCheck)) {
  throw 'Bloc class/section validation insertion point not found.'
}
$bloc = $bloc.Replace($oldExamCheck, $newExamCheck)

$oldGenerateCall = @'
      await _generateExamResults(examId, actorId: actorId);
'@

$newGenerateCall = @'
      await _generateExamResults(
        examId,
        classId: classId,
        sectionId: sectionId,
        actorId: actorId,
      );
'@

if (-not $bloc.Contains($oldGenerateCall)) {
  throw 'Bloc generate call not found.'
}
$bloc = $bloc.Replace($oldGenerateCall, $newGenerateCall)

SaveText $blocPath $bloc

$usecase = [IO.File]::ReadAllText((Full $usecasePath)).Replace("`r`n", "`n")

$oldSignature = @'
  Future<List<ExamResultEntity>> call(
    String examId, {
    String actorId = '',
  }) async {
    final normalizedExamId = examId.trim();
    final normalizedActorId = actorId.trim();
'@

$newSignature = @'
  Future<List<ExamResultEntity>> call(
    String examId, {
    required String classId,
    required String sectionId,
    String actorId = '',
  }) async {
    final normalizedExamId = examId.trim();
    final normalizedClassId = classId.trim();
    final normalizedSectionId = sectionId.trim();
    final normalizedActorId = actorId.trim();
'@

if (-not $usecase.Contains($oldSignature)) {
  throw 'GenerateExamResults signature not found.'
}
$usecase = $usecase.Replace($oldSignature, $newSignature)

$oldValidation = @'
    if (normalizedExamId.isEmpty) {
      throw ArgumentError.value(
        examId,
        'examId',
        'Exam ID cannot be empty.',
      );
    }
'@

$newValidation = @'
    if (normalizedExamId.isEmpty) {
      throw ArgumentError.value(
        examId,
        'examId',
        'Exam ID cannot be empty.',
      );
    }

    if (normalizedClassId.isEmpty) {
      throw ArgumentError.value(
        classId,
        'classId',
        'Class ID cannot be empty.',
      );
    }

    if (normalizedSectionId.isEmpty) {
      throw ArgumentError.value(
        sectionId,
        'sectionId',
        'Section ID cannot be empty.',
      );
    }
'@

if (-not $usecase.Contains($oldValidation)) {
  throw 'GenerateExamResults validation block not found.'
}
$usecase = $usecase.Replace($oldValidation, $newValidation)

$oldSetups = @'
    final setups = await componentService.expandSetups(
      (responses[1] as List<ExamSubjectSetupEntity>)
          .where((setup) => setup.isActive)
          .toList(growable: false),
    );

    final marks = responses[2] as List<ExamMarkEntity>;
'@

$newSetups = @'
    final setups = await componentService.expandSetups(
      (responses[1] as List<ExamSubjectSetupEntity>)
          .where(
            (setup) =>
                setup.isActive &&
                setup.classId == normalizedClassId &&
                setup.sectionId == normalizedSectionId,
          )
          .toList(growable: false),
    );

    final marks = (responses[2] as List<ExamMarkEntity>)
        .where(
          (mark) =>
              mark.classId == normalizedClassId &&
              mark.sectionId == normalizedSectionId,
        )
        .toList(growable: false);
'@

if (-not $usecase.Contains($oldSetups)) {
  throw 'Setups and marks filtering block not found.'
}
$usecase = $usecase.Replace($oldSetups, $newSetups)

$oldExisting = @'
    final existingResults =
        responses[4] as List<ExamResultEntity>;
'@

$newExisting = @'
    final existingResults =
        (responses[4] as List<ExamResultEntity>)
            .where(
              (result) =>
                  result.classId == normalizedClassId &&
                  result.sectionId == normalizedSectionId,
            )
            .toList(growable: false);
'@

if (-not $usecase.Contains($oldExisting)) {
  throw 'Existing results filtering block not found.'
}
$usecase = $usecase.Replace($oldExisting, $newExisting)

$oldEmptySetupMessage = @'
    if (setups.isEmpty) {
      throw StateError(
        'Add active subject setups before generating results.',
      );
    }
'@

$newEmptySetupMessage = @'
    if (setups.isEmpty) {
      throw StateError(
        'No active subject setups were found for the selected class and section.',
      );
    }
'@

if (-not $usecase.Contains($oldEmptySetupMessage)) {
  throw 'Empty setup message block not found.'
}
$usecase = $usecase.Replace($oldEmptySetupMessage, $newEmptySetupMessage)

$oldGeneratedEmpty = @'
    if (generated.isEmpty) {
      throw StateError(
        'No active students were found for the configured classes.',
      );
    }
'@

$newGeneratedEmpty = @'
    if (generated.isEmpty) {
      throw StateError(
        'No active students were found for the selected class and section.',
      );
    }
'@

if (-not $usecase.Contains($oldGeneratedEmpty)) {
  throw 'Generated empty message block not found.'
}
$usecase = $usecase.Replace($oldGeneratedEmpty, $newGeneratedEmpty)

SaveText $usecasePath $usecase

dart format $blocPath $usecasePath
if ($LASTEXITCODE -ne 0) {
  throw "FORMAT ERROR. Backup: $backup"
}

flutter analyze lib/features/exams --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) {
  throw "ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Result generation filter bug fixed successfully.' -ForegroundColor Green
Write-Host 'Generate Results now uses only the selected Exam + Class + Section.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
