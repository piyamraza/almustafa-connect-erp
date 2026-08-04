[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\audit_phase3_students_$stamp"

function Full([string]$Path) { Join-Path $root $Path }
function ReadText([string]$Path) { [IO.File]::ReadAllText((Full $Path)) }
function WriteText([string]$Path, [string]$Text) {
  $full = Full $Path
  $dir = Split-Path $full -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  [IO.File]::WriteAllText($full, $Text.Replace("`r`n", "`n"), $utf8)
}
function BackupFile([string]$Path) {
  $source = Full $Path
  if (-not (Test-Path $source)) { return }
  $target = Join-Path $backup $Path
  $dir = Split-Path $target -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  Copy-Item $source $target -Force
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run this script from the Flutter project root.'
}

$repositoryFile = 'lib/features/students/data/repositories/student_repository_impl.dart'
$serviceLocator = 'lib/core/di/service_locator.dart'
$auditServiceFile = 'lib/core/audit/domain/services/audit_service.dart'

foreach ($path in @($repositoryFile, $serviceLocator, $auditServiceFile)) {
  if (-not (Test-Path (Full $path))) { throw "REQUIRED FILE ERROR: $path" }
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
BackupFile $repositoryFile
BackupFile $serviceLocator

WriteText $repositoryFile @'
import 'dart:typed_data';

import '../../../../core/audit/domain/services/audit_service.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/student_repository.dart';
import '../datasources/student_remote_datasource.dart';
import '../models/student_model.dart';

class StudentRepositoryImpl implements StudentRepository {
  StudentRepositoryImpl({
    required StudentRemoteDataSource remoteDataSource,
    required AuditService auditService,
  }) : _remoteDataSource = remoteDataSource,
       _auditService = auditService;

  final StudentRemoteDataSource _remoteDataSource;
  final AuditService _auditService;

  @override
  Future<List<StudentEntity>> getStudents() {
    return _remoteDataSource.getStudents();
  }

  @override
  Future<List<StudentEntity>> getStudentsByClassAndSection({
    required String classId,
    required String sectionId,
  }) {
    return _remoteDataSource.getStudentsByClassAndSection(
      classId: classId,
      sectionId: sectionId,
    );
  }

  @override
  Future<StudentEntity?> getStudentById(String id) {
    return _remoteDataSource.getStudentById(id);
  }

  @override
  Future<void> addStudent(StudentEntity student) async {
    final model = StudentModel.fromEntity(student);

    await _remoteDataSource.addStudent(model);

    await _auditService.logCreate(
      module: 'Students',
      recordId: student.id,
      description: 'Student record created',
      newValues: _auditValues(model),
    );
  }

  @override
  Future<void> updateStudent(StudentEntity student) async {
    final previous = await _remoteDataSource.getStudentById(student.id);
    final model = StudentModel.fromEntity(student);

    await _remoteDataSource.updateStudent(model);

    await _auditService.logUpdate(
      module: 'Students',
      recordId: student.id,
      description: 'Student record updated',
      oldValues: previous == null
          ? const {}
          : _auditValues(StudentModel.fromEntity(previous)),
      newValues: _auditValues(model),
    );
  }

  @override
  Future<void> deleteStudent(String id) async {
    final previous = await _remoteDataSource.getStudentById(id);

    await _remoteDataSource.deleteStudent(id);

    await _auditService.logDelete(
      module: 'Students',
      recordId: id,
      description: 'Student record deleted',
      oldValues: previous == null
          ? const {}
          : _auditValues(StudentModel.fromEntity(previous)),
    );
  }

  @override
  Future<List<StudentEntity>> searchStudents(String keyword) {
    return _remoteDataSource.searchStudents(keyword);
  }

  @override
  String generateStudentId() {
    return _remoteDataSource.generateStudentId();
  }

  @override
  Future<String> uploadStudentPhoto(
    String studentId,
    Uint8List imageBytes,
  ) async {
    final imageUrl = await _remoteDataSource.uploadStudentPhoto(
      studentId,
      imageBytes,
    );

    await _auditService.logUpdate(
      module: 'Students',
      recordId: studentId,
      description: 'Student profile photo uploaded',
      newValues: {'profileImageUrl': imageUrl},
    );

    return imageUrl;
  }

  Map<String, dynamic> _auditValues(StudentModel model) {
    final values = Map<String, dynamic>.from(model.toMap());
    values.remove('fatherCnic');
    values.remove('motherCnic');
    values.remove('guardianCnic');
    return values;
  }
}
'@

$locatorText = ReadText $serviceLocator
$normalized = $locatorText.Replace("`r`n", "`n")

if (-not ($normalized -match 'StudentRepositoryImpl\s*\([\s\S]*?auditService\s*:')) {
  $patterns = @(
    '(?s)StudentRepositoryImpl\s*\(\s*_remoteDataSource\s*:\s*sl<StudentRemoteDataSource>\(\)\s*,?\s*\)',
    '(?s)StudentRepositoryImpl\s*\(\s*remoteDataSource\s*:\s*sl<StudentRemoteDataSource>\(\)\s*,?\s*\)',
    '(?s)StudentRepositoryImpl\s*\(\s*sl<StudentRemoteDataSource>\(\)\s*\)'
  )

  $replacement = @'
StudentRepositoryImpl(
      remoteDataSource: sl<StudentRemoteDataSource>(),
      auditService: sl<AuditService>(),
    )
'@

  $matched = $false
  foreach ($pattern in $patterns) {
    if ([regex]::IsMatch($normalized, $pattern)) {
      $normalized = [regex]::Replace($normalized, $pattern, $replacement, 1)
      $matched = $true
      break
    }
  }

  if (-not $matched) {
    throw 'SERVICE LOCATOR STUDENT REPOSITORY ANCHOR ERROR.'
  }

  WriteText $serviceLocator $normalized
}

& dart format $repositoryFile $serviceLocator
if ($LASTEXITCODE -ne 0) { throw "DART FORMAT ERROR. Backup: $backup" }

& flutter analyze lib/features/students lib/core/audit $serviceLocator --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) { throw "AUDIT PHASE 3 STUDENTS ANALYZE ERROR. Backup: $backup" }

Write-Host ''
Write-Host 'Audit Phase 3 - Students integration completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host 'Audited actions: create, update, delete, and profile-photo upload.' -ForegroundColor Yellow
Write-Host 'Sensitive CNIC values are excluded from audit payloads.' -ForegroundColor Yellow
