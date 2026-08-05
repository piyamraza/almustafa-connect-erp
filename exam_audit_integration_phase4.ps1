[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\exam_audit_integration_$stamp"

function Full([string]$path) {
  Join-Path $root $path
}

function BackupFile([string]$path) {
  $source = Full $path
  if (-not (Test-Path $source)) {
    throw "Required file not found: $path"
  }

  $target = Join-Path $backup $path
  New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
  Copy-Item $source $target -Force
}

function WriteFile([string]$path, [string]$text) {
  $target = Full $path
  $temp = "$target.audit_tmp"

  [IO.File]::WriteAllText(
    $temp,
    $text.Replace("`r`n", "`n"),
    $utf8
  )

  Copy-Item $temp $target -Force
  Remove-Item $temp -Force
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'Run this script from the project root.'
}

$repository = 'lib/features/exams/data/repositories/exam_repository_impl.dart'
$serviceLocator = 'lib/core/di/service_locator.dart'

BackupFile $repository
BackupFile $serviceLocator

WriteFile $repository @'
import '../../../../core/audit/domain/services/audit_service.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/repositories/exam_repository.dart';
import '../datasources/exam_remote_datasource.dart';
import '../models/exam_model.dart';

class ExamRepositoryImpl implements ExamRepository {
  ExamRepositoryImpl({
    required ExamRemoteDataSource source,
    required AuditService auditService,
  })  : _source = source,
        _auditService = auditService;

  final ExamRemoteDataSource _source;
  final AuditService _auditService;

  @override
  Future<List<ExamEntity>> getExams({
    String? academicSession,
    bool? isActive,
  }) {
    return _source.getExams(
      academicSession: academicSession,
      isActive: isActive,
    );
  }

  @override
  Future<ExamEntity?> getExamById(String id) {
    return _source.getExamById(id);
  }

  @override
  Future<void> createExam(ExamEntity exam) async {
    final model = ExamModel.fromEntity(exam);

    await _source.createExam(model);

    await _auditService.logCreate(
      module: 'Examinations',
      recordId: exam.id,
      description: 'Exam created: ${exam.name}',
      newValues: model.toMap(),
    );
  }

  @override
  Future<void> updateExam(ExamEntity exam) async {
    final previous = await _source.getExamById(exam.id);
    final model = ExamModel.fromEntity(exam);

    await _source.updateExam(model);

    await _auditService.logUpdate(
      module: 'Examinations',
      recordId: exam.id,
      description: 'Exam updated: ${exam.name}',
      oldValues: previous == null
          ? const {}
          : ExamModel.fromEntity(previous).toMap(),
      newValues: model.toMap(),
    );
  }

  @override
  Future<void> deleteExam(String id) async {
    final previous = await _source.getExamById(id);

    await _source.deleteExam(id);

    await _auditService.logDelete(
      module: 'Examinations',
      recordId: id,
      description: previous == null
          ? 'Exam deleted'
          : 'Exam deleted: ${previous.name}',
      oldValues: previous == null
          ? const {}
          : ExamModel.fromEntity(previous).toMap(),
    );
  }

  @override
  Future<void> setExamActiveStatus({
    required String id,
    required bool isActive,
  }) async {
    final previous = await _source.getExamById(id);

    await _source.setExamActiveStatus(
      id: id,
      isActive: isActive,
    );

    await _auditService.logUpdate(
      module: 'Examinations',
      recordId: id,
      description: isActive ? 'Exam activated' : 'Exam deactivated',
      oldValues: {
        if (previous != null) ...ExamModel.fromEntity(previous).toMap(),
      },
      newValues: {
        'isActive': isActive,
        'status': isActive ? 'active' : 'draft',
      },
    );
  }

  @override
  String generateId() {
    return _source.generateId();
  }
}
'@

$di = [IO.File]::ReadAllText((Full $serviceLocator)).Replace("`r`n", "`n")

if (-not $di.Contains('auditService: sl<AuditService>()')) {
  $regex = 'sl\.registerLazySingleton<ExamRepository>\(\s*\(\)\s*=>\s*ExamRepositoryImpl\([\s\S]*?\),\s*\);'
  $match = [regex]::Match($di, $regex)

  if (-not $match.Success) {
    throw 'ExamRepository DI registration was not found in service_locator.dart.'
  }

  $replacement = @'
sl.registerLazySingleton<ExamRepository>(
  () => ExamRepositoryImpl(
    source: sl<ExamRemoteDataSource>(),
    auditService: sl<AuditService>(),
  ),
);
'@

  $di = $di.Remove($match.Index, $match.Length)
  $di = $di.Insert($match.Index, $replacement.Trim())
  WriteFile $serviceLocator $di
}

Write-Host ''
Write-Host 'Exam Audit Integration completed successfully.' -ForegroundColor Green
Write-Host 'Exam create, update, delete and active-status changes now generate audit logs.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Now run:' -ForegroundColor Yellow
Write-Host 'dart format .\lib\features\exams\data\repositories\exam_repository_impl.dart .\lib\core\di\service_locator.dart'
Write-Host 'flutter analyze lib\features\exams lib\core\audit lib\core\di --no-fatal-infos --no-fatal-warnings'
