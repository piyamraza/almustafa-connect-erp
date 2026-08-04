[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\parent_homework_phase2c_part1_$stamp"

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

$summary='lib/features/parent_portal/domain/entities/parent_homework_summary.dart'
$service='lib/features/parent_portal/domain/services/parent_homework_service.dart'
$impl='lib/features/parent_portal/data/services/parent_homework_service_impl.dart'
$di='lib/features/parent_portal/parent_homework_di.dart'
$sl='lib/core/di/service_locator.dart'

foreach($f in @($summary,$service,$impl,$di,$sl)){BackupFile $f}

WriteText $summary @'
import '../../../homework/domain/entities/homework_entity.dart';

class ParentHomeworkSummary {
  const ParentHomeworkSummary({
    required this.items,
    required this.total,
    required this.dueToday,
    required this.upcoming,
    required this.overdue,
  });

  final List<HomeworkEntity> items;
  final int total;
  final int dueToday;
  final int upcoming;
  final int overdue;
}
'@

WriteText $service @'
import '../entities/parent_homework_summary.dart';

abstract class ParentHomeworkService {
  Future<ParentHomeworkSummary> loadHomework({
    required String academicSession,
    required String classId,
    required String sectionId,
  });
}
'@

WriteText $impl @'
import '../../../homework/domain/entities/homework_entity.dart';
import '../../../homework/domain/repositories/homework_repository.dart';
import '../../domain/entities/parent_homework_summary.dart';
import '../../domain/services/parent_homework_service.dart';

class ParentHomeworkServiceImpl
    implements ParentHomeworkService {
  const ParentHomeworkServiceImpl(this._repository);

  final HomeworkRepository _repository;

  @override
  Future<ParentHomeworkSummary> loadHomework({
    required String academicSession,
    required String classId,
    required String sectionId,
  }) async {
    final values = await _repository.getHomework(
      academicSession: academicSession,
      status: HomeworkStatus.published,
      classId: classId.trim(),
      sectionId: sectionId.trim(),
    );

    final items = values.toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final today = DateTime.now();
    final startOfToday = DateTime(
      today.year,
      today.month,
      today.day,
    );
    final endOfToday = DateTime(
      today.year,
      today.month,
      today.day,
      23,
      59,
      59,
    );

    var dueToday = 0;
    var upcoming = 0;
    var overdue = 0;

    for (final item in items) {
      if (item.dueDate.isBefore(startOfToday)) {
        overdue++;
      } else if (!item.dueDate.isAfter(endOfToday)) {
        dueToday++;
      } else {
        upcoming++;
      }
    }

    return ParentHomeworkSummary(
      items: List<HomeworkEntity>.unmodifiable(items),
      total: items.length,
      dueToday: dueToday,
      upcoming: upcoming,
      overdue: overdue,
    );
  }
}
'@

WriteText $di @'
import 'package:get_it/get_it.dart';

import '../homework/domain/repositories/homework_repository.dart';
import 'data/services/parent_homework_service_impl.dart';
import 'domain/services/parent_homework_service.dart';

void registerParentHomeworkDependencies(GetIt sl) {
  if (!sl.isRegistered<ParentHomeworkService>()) {
    sl.registerLazySingleton<ParentHomeworkService>(
      () => ParentHomeworkServiceImpl(
        sl<HomeworkRepository>(),
      ),
    );
  }
}
'@

$text=[IO.File]::ReadAllText((Full $sl)).Replace("`r`n","`n")

$import="import '../../features/parent_portal/parent_homework_di.dart';"
if(-not $text.Contains($import)){
  $idx=$text.IndexOf('import ')
  if($idx -lt 0){throw 'Import anchor not found.'}
  $text=$text.Insert($idx,"$import`n")
}

$call='registerParentHomeworkDependencies(sl);'
if(-not $text.Contains($call)){
  $anchor='Future<void> setupServiceLocator() async {'
  $idx=$text.IndexOf($anchor)
  if($idx -lt 0){throw 'setupServiceLocator anchor not found.'}
  $text=$text.Insert($idx+$anchor.Length,"`n  $call")
}

WriteText $sl $text

dart format $summary $service $impl $di $sl
if($LASTEXITCODE -ne 0){throw "FORMAT ERROR. Backup: $backup"}

flutter analyze lib/features/parent_portal lib/features/homework $sl --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){throw "ANALYZE ERROR. Backup: $backup"}

Write-Host ''
Write-Host 'Parent Homework Phase 2C Part 1 completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
