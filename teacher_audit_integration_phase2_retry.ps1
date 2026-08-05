[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\teacher_audit_integration_retry_$stamp"

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

function WriteFileWithRetry([string]$path, [string]$text) {
  $target = Full $path
  $directory = Split-Path $target -Parent
  $temp = Join-Path $directory ('.' + [IO.Path]::GetFileName($target) + '.audit_tmp')

  [IO.File]::WriteAllText(
    $temp,
    $text.Replace("`r`n", "`n"),
    $utf8
  )

  for ($attempt = 1; $attempt -le 10; $attempt++) {
    try {
      Copy-Item $temp $target -Force
      Remove-Item $temp -Force
      return
    } catch {
      if ($attempt -eq 10) {
        throw "Could not replace locked file: $path`nClose the running app and VS Code, then retry.`n$($_.Exception.Message)"
      }
      Start-Sleep -Milliseconds 700
    }
  }
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'Run this script from the project root.'
}

Write-Host 'Stopping Flutter/Dart analyzer processes that may be locking files...' -ForegroundColor Yellow
Get-Process dart, dartaotruntime, flutter -ErrorAction SilentlyContinue |
  Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2

$datasource = 'lib/features/teachers/data/datasources/teacher_remote_datasource.dart'
$repository = 'lib/features/teachers/data/repositories/teacher_repository_impl.dart'
$serviceLocator = 'lib/core/di/service_locator.dart'

BackupFile $datasource
BackupFile $repository
BackupFile $serviceLocator

WriteFileWithRetry $datasource @'
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/teacher_model.dart';

abstract class TeacherRemoteDataSource {
  Future<List<TeacherModel>> getTeachers();

  Future<TeacherModel?> getTeacherById(String id);

  Future<void> saveTeacher(TeacherModel teacher);

  Future<void> deleteTeacher(String id);

  String generateTeacherId();
}

class TeacherRemoteDataSourceImpl implements TeacherRemoteDataSource {
  TeacherRemoteDataSourceImpl({required this._firestoreService});

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<TeacherModel>> getTeachers() async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.teachers)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (document) => TeacherModel.fromMap({
            ...document.data(),
            'id': document.id,
          }),
        )
        .toList(growable: false);
  }

  @override
  Future<TeacherModel?> getTeacherById(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return null;

    final snapshot = await _firestoreService
        .collection(FirestorePaths.teachers)
        .doc(normalizedId)
        .get();

    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;

    return TeacherModel.fromMap({
      ...data,
      'id': snapshot.id,
    });
  }

  @override
  Future<void> saveTeacher(TeacherModel teacher) {
    return _firestoreService
        .collection(FirestorePaths.teachers)
        .doc(teacher.id)
        .set(teacher.toMap());
  }

  @override
  Future<void> deleteTeacher(String id) {
    return _firestoreService
        .collection(FirestorePaths.teachers)
        .doc(id)
        .delete();
  }

  @override
  String generateTeacherId() {
    return _firestoreService
        .collection(FirestorePaths.teachers)
        .doc()
        .id;
  }
}
'@

WriteFileWithRetry $repository @'
import '../../../../core/audit/domain/services/audit_service.dart';
import '../../domain/entities/teacher_entity.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/teacher_remote_datasource.dart';
import '../models/teacher_model.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  TeacherRepositoryImpl({
    required TeacherRemoteDataSource remoteDataSource,
    required AuditService auditService,
  })  : _remoteDataSource = remoteDataSource,
        _auditService = auditService;

  final TeacherRemoteDataSource _remoteDataSource;
  final AuditService _auditService;

  @override
  Future<List<TeacherEntity>> getTeachers() {
    return _remoteDataSource.getTeachers();
  }

  @override
  Future<void> saveTeacher(TeacherEntity teacher) async {
    final previous = await _remoteDataSource.getTeacherById(teacher.id);
    final model = TeacherModel.fromEntity(teacher);

    await _remoteDataSource.saveTeacher(model);

    if (previous == null) {
      await _auditService.logCreate(
        module: 'Teachers',
        recordId: teacher.id,
        description: 'Teacher record created',
        newValues: _auditValues(model),
      );
      return;
    }

    await _auditService.logUpdate(
      module: 'Teachers',
      recordId: teacher.id,
      description: 'Teacher record updated',
      oldValues: _auditValues(previous),
      newValues: _auditValues(model),
    );
  }

  @override
  Future<void> deleteTeacher(String id) async {
    final previous = await _remoteDataSource.getTeacherById(id);

    await _remoteDataSource.deleteTeacher(id);

    await _auditService.logDelete(
      module: 'Teachers',
      recordId: id,
      description: 'Teacher record deleted',
      oldValues: previous == null ? const {} : _auditValues(previous),
    );
  }

  @override
  String generateTeacherId() {
    return _remoteDataSource.generateTeacherId();
  }

  Map<String, dynamic> _auditValues(TeacherModel model) {
    final values = Map<String, dynamic>.from(model.toMap());
    values.remove('cnic');
    return values;
  }
}
'@

$serviceText = [IO.File]::ReadAllText((Full $serviceLocator)).Replace("`r`n", "`n")

$oldRegistration = @'
  sl.registerLazySingleton<TeacherRepository>(
    () =>
        TeacherRepositoryImpl(remoteDataSource: sl<TeacherRemoteDataSource>()),
  );
'@

$newRegistration = @'
  sl.registerLazySingleton<TeacherRepository>(
    () => TeacherRepositoryImpl(
      remoteDataSource: sl<TeacherRemoteDataSource>(),
      auditService: sl<AuditService>(),
    ),
  );
'@

if ($serviceText.Contains($newRegistration)) {
  Write-Host 'TeacherRepository DI registration is already updated.' -ForegroundColor Cyan
} elseif ($serviceText.Contains($oldRegistration)) {
  $serviceText = $serviceText.Replace($oldRegistration, $newRegistration)
  WriteFileWithRetry $serviceLocator $serviceText
} else {
  throw 'TeacherRepository registration block was not found in service_locator.dart.'
}

Write-Host ''
Write-Host 'Teacher Audit Integration completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Now run:' -ForegroundColor Yellow
Write-Host 'dart format .\lib\features\teachers\data\datasources\teacher_remote_datasource.dart .\lib\features\teachers\data\repositories\teacher_repository_impl.dart .\lib\core\di\service_locator.dart'
Write-Host 'flutter analyze lib\features\teachers lib\core\audit lib\core\di --no-fatal-infos --no-fatal-warnings'
