[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\audit_phase4_attendance_$stamp"

function Full([string]$Path) { Join-Path $root $Path }
function ReadText([string]$Path) { [IO.File]::ReadAllText((Full $Path)) }

function WriteText([string]$Path, [string]$Text) {
  $full = Full $Path
  $dir = Split-Path $full -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  [IO.File]::WriteAllText(
    $full,
    $Text.Replace("`r`n", "`n"),
    $utf8
  )
}

function BackupFile([string]$Path) {
  $source = Full $Path
  if (-not (Test-Path $source)) { return }

  $target = Join-Path $backup $Path
  $dir = Split-Path $target -Parent

  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }

  Copy-Item $source $target -Force
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run this script from the Flutter project root.'
}

$repositoryFile =
  'lib/features/attendance/data/repositories/attendance_repository_impl.dart'
$serviceLocator =
  'lib/core/di/service_locator.dart'
$auditServiceFile =
  'lib/core/audit/domain/services/audit_service.dart'

foreach ($path in @(
  $repositoryFile,
  $serviceLocator,
  $auditServiceFile
)) {
  if (-not (Test-Path (Full $path))) {
    throw "REQUIRED FILE ERROR: $path"
  }
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
BackupFile $repositoryFile
BackupFile $serviceLocator

WriteText $repositoryFile @'
import '../../../../core/audit/domain/services/audit_service.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl
    implements AttendanceRepository {
  AttendanceRepositoryImpl({
    required AttendanceRemoteDataSource remoteDataSource,
    required AuditService auditService,
  }) : _remoteDataSource = remoteDataSource,
       _auditService = auditService;

  final AttendanceRemoteDataSource _remoteDataSource;
  final AuditService _auditService;

  @override
  Future<List<AttendanceEntity>> getAttendance() {
    return _remoteDataSource.getAttendance();
  }

  @override
  Future<void> addAttendance(
    AttendanceEntity attendance,
  ) async {
    final model = AttendanceModel.fromEntity(attendance);

    await _remoteDataSource.addAttendance(model);

    await _auditService.logCreate(
      module: 'Attendance',
      recordId: attendance.id,
      description: 'Daily student attendance recorded',
      newValues: model.toMap(),
    );
  }

  @override
  Future<void> updateAttendance(
    AttendanceEntity attendance,
  ) async {
    final previous = await _findById(attendance.id);
    final model = AttendanceModel.fromEntity(attendance);

    await _remoteDataSource.updateAttendance(model);

    await _auditService.logUpdate(
      module: 'Attendance',
      recordId: attendance.id,
      description: 'Daily student attendance corrected',
      oldValues: previous == null
          ? const {}
          : AttendanceModel.fromEntity(previous).toMap(),
      newValues: model.toMap(),
    );
  }

  @override
  Future<void> deleteAttendance(
    String attendanceId,
  ) async {
    final previous = await _findById(attendanceId);

    await _remoteDataSource.deleteAttendance(
      attendanceId,
    );

    await _auditService.logDelete(
      module: 'Attendance',
      recordId: attendanceId,
      description: 'Daily student attendance deleted',
      oldValues: previous == null
          ? const {}
          : AttendanceModel.fromEntity(previous).toMap(),
    );
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceByDate(
    DateTime date,
  ) {
    return _remoteDataSource.getAttendanceByDate(
      date,
    );
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceByStudent(
    String studentId,
  ) {
    return _remoteDataSource.getAttendanceByStudent(
      studentId,
    );
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceForReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _remoteDataSource.getAttendanceForReport(
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  @override
  String generateAttendanceId() {
    return _remoteDataSource.generateAttendanceId();
  }

  Future<AttendanceEntity?> _findById(String id) async {
    final records = await _remoteDataSource.getAttendance();

    for (final item in records) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }
}
'@

$locatorText = ReadText $serviceLocator
$normalized = $locatorText.Replace("`r`n", "`n")

if (-not (
  $normalized -match
  'AttendanceRepositoryImpl\s*\([\s\S]*?auditService\s*:'
)) {
  $patterns = @(
    '(?s)AttendanceRepositoryImpl\s*\(\s*remoteDataSource\s*:\s*sl<AttendanceRemoteDataSource>\(\)\s*,?\s*\)',
    '(?s)AttendanceRepositoryImpl\s*\(\s*_remoteDataSource\s*:\s*sl<AttendanceRemoteDataSource>\(\)\s*,?\s*\)',
    '(?s)AttendanceRepositoryImpl\s*\(\s*sl<AttendanceRemoteDataSource>\(\)\s*\)'
  )

  $replacement = @'
AttendanceRepositoryImpl(
      remoteDataSource: sl<AttendanceRemoteDataSource>(),
      auditService: sl<AuditService>(),
    )
'@

  $matched = $false

  foreach ($pattern in $patterns) {
    if ([regex]::IsMatch($normalized, $pattern)) {
      $normalized = [regex]::Replace(
        $normalized,
        $pattern,
        $replacement,
        1
      )
      $matched = $true
      break
    }
  }

  if (-not $matched) {
    throw 'SERVICE LOCATOR ATTENDANCE REPOSITORY ANCHOR ERROR.'
  }

  WriteText $serviceLocator $normalized
}

& dart format `
  $repositoryFile `
  $serviceLocator

if ($LASTEXITCODE -ne 0) {
  throw "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze `
  lib/features/attendance `
  lib/core/audit `
  $serviceLocator `
  --no-fatal-infos `
  --no-fatal-warnings

if ($LASTEXITCODE -ne 0) {
  throw "AUDIT PHASE 4 ATTENDANCE ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Audit Phase 4 - Attendance integration completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Audited actions: daily attendance create, correction, and delete.' -ForegroundColor Yellow
Write-Host 'Attendance remains one record per student per day; no period-wise audit was added.' -ForegroundColor Yellow
