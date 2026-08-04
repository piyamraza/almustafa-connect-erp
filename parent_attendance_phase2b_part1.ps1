[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\parent_attendance_phase2b_part1_$stamp"

function Full([string]$p){Join-Path $root $p}
function BackupFile([string]$p){
  $s=Full $p
  if(Test-Path $s){
    $d=Join-Path $backup $p
    New-Item -ItemType Directory -Force -Path (Split-Path $d -Parent)|Out-Null
    Copy-Item $s $d -Force
  }
}
function WriteText([string]$p,[string]$t){
  $f=Full $p
  New-Item -ItemType Directory -Force -Path (Split-Path $f -Parent)|Out-Null
  [IO.File]::WriteAllText($f,$t.Replace("`r`n","`n"),$utf8)
}

if(-not(Test-Path (Full 'pubspec.yaml'))){throw 'Run from project root.'}

$summary='lib/features/parent_portal/domain/entities/parent_attendance_summary.dart'
$service='lib/features/parent_portal/domain/services/parent_attendance_service.dart'
$impl='lib/features/parent_portal/data/services/parent_attendance_service_impl.dart'
$di='lib/features/parent_portal/parent_attendance_di.dart'
$sl='lib/core/di/service_locator.dart'

foreach($f in @($summary,$service,$impl,$di,$sl)){BackupFile $f}

WriteText $summary @'
import '../../../attendance/domain/entities/attendance_entity.dart';

class ParentAttendanceSummary {
  const ParentAttendanceSummary({
    required this.records,
    required this.total,
    required this.present,
    required this.absent,
    required this.leave,
    required this.late,
  });

  final List<AttendanceEntity> records;
  final int total;
  final int present;
  final int absent;
  final int leave;
  final int late;

  double get attendancePercentage {
    if (total == 0) return 0;
    return ((present + late) / total) * 100;
  }
}
'@

WriteText $service @'
import '../entities/parent_attendance_summary.dart';

abstract class ParentAttendanceService {
  Future<ParentAttendanceSummary> loadMonthlyAttendance({
    required String studentId,
    required int year,
    required int month,
  });

  Future<ParentAttendanceSummary> loadAttendanceRange({
    required String studentId,
    required DateTime fromDate,
    required DateTime toDate,
  });
}
'@

WriteText $impl @'
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../domain/entities/parent_attendance_summary.dart';
import '../../domain/services/parent_attendance_service.dart';

class ParentAttendanceServiceImpl
    implements ParentAttendanceService {
  const ParentAttendanceServiceImpl(this._repository);

  final AttendanceRepository _repository;

  @override
  Future<ParentAttendanceSummary> loadMonthlyAttendance({
    required String studentId,
    required int year,
    required int month,
  }) {
    final fromDate = DateTime(year, month, 1);
    final toDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return loadAttendanceRange(
      studentId: studentId,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  @override
  Future<ParentAttendanceSummary> loadAttendanceRange({
    required String studentId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final values = await _repository.getAttendanceByStudent(
      studentId.trim(),
    );

    final records = values
        .where(
          (record) =>
              !record.attendanceDate.isBefore(fromDate) &&
              !record.attendanceDate.isAfter(toDate),
        )
        .toList()
      ..sort(
        (a, b) => b.attendanceDate.compareTo(a.attendanceDate),
      );

    var present = 0;
    var absent = 0;
    var leave = 0;
    var late = 0;

    for (final record in records) {
      switch (record.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.leave:
          leave++;
          break;
        case AttendanceStatus.late:
          late++;
          break;
      }
    }

    return ParentAttendanceSummary(
      records: List<AttendanceEntity>.unmodifiable(records),
      total: records.length,
      present: present,
      absent: absent,
      leave: leave,
      late: late,
    );
  }
}
'@

WriteText $di @'
import 'package:get_it/get_it.dart';

import '../attendance/domain/repositories/attendance_repository.dart';
import 'data/services/parent_attendance_service_impl.dart';
import 'domain/services/parent_attendance_service.dart';

void registerParentAttendanceDependencies(GetIt sl) {
  if (!sl.isRegistered<ParentAttendanceService>()) {
    sl.registerLazySingleton<ParentAttendanceService>(
      () => ParentAttendanceServiceImpl(
        sl<AttendanceRepository>(),
      ),
    );
  }
}
'@

$text=[IO.File]::ReadAllText((Full $sl)).Replace("`r`n","`n")

$import="import '../../features/parent_portal/parent_attendance_di.dart';"
if(-not $text.Contains($import)){
  $idx=$text.IndexOf('import ')
  if($idx -lt 0){throw 'Import anchor not found.'}
  $text=$text.Insert($idx,"$import`n")
}

$call='registerParentAttendanceDependencies(sl);'
if(-not $text.Contains($call)){
  $anchor='Future<void> setupServiceLocator() async {'
  $idx=$text.IndexOf($anchor)
  if($idx -lt 0){throw 'setupServiceLocator anchor not found.'}
  $insert=$idx+$anchor.Length
  $text=$text.Insert($insert,"`n  $call")
}

WriteText $sl $text

dart format $summary $service $impl $di $sl
if($LASTEXITCODE -ne 0){throw "FORMAT ERROR. Backup: $backup"}

flutter analyze lib/features/parent_portal lib/features/attendance $sl --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){throw "ANALYZE ERROR. Backup: $backup"}

Write-Host ''
Write-Host 'Parent Attendance Phase 2B Part 1 completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
