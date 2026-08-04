[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\parent_results_phase2d_part1_$stamp"

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

$summary='lib/features/parent_portal/domain/entities/parent_results_summary.dart'
$service='lib/features/parent_portal/domain/services/parent_results_service.dart'
$impl='lib/features/parent_portal/data/services/parent_results_service_impl.dart'
$di='lib/features/parent_portal/parent_results_di.dart'
$sl='lib/core/di/service_locator.dart'

foreach($f in @($summary,$service,$impl,$di,$sl)){BackupFile $f}

WriteText $summary @'
import '../../../exams/domain/entities/exam_result_entity.dart';

class ParentResultsSummary {
  const ParentResultsSummary({
    required this.results,
    required this.latestResult,
    required this.totalPublishedResults,
    required this.averagePercentage,
    required this.passedResults,
    required this.failedResults,
  });

  final List<ExamResultEntity> results;
  final ExamResultEntity? latestResult;
  final int totalPublishedResults;
  final double averagePercentage;
  final int passedResults;
  final int failedResults;
}
'@

WriteText $service @'
import '../entities/parent_results_summary.dart';

abstract class ParentResultsService {
  Future<ParentResultsSummary> loadPublishedResults({
    required String studentId,
    String? examId,
    String? classId,
    String? sectionId,
  });
}
'@

WriteText $impl @'
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/domain/repositories/exam_result_repository.dart';
import '../../domain/entities/parent_results_summary.dart';
import '../../domain/services/parent_results_service.dart';

class ParentResultsServiceImpl
    implements ParentResultsService {
  const ParentResultsServiceImpl(this._repository);

  final ExamResultRepository _repository;

  @override
  Future<ParentResultsSummary> loadPublishedResults({
    required String studentId,
    String? examId,
    String? classId,
    String? sectionId,
  }) async {
    final values = await _repository.getPublishedResults(
      studentId: studentId.trim(),
      examId: examId,
      classId: classId,
      sectionId: sectionId,
    );

    final results = values
        .where((result) => result.isVisibleToParent)
        .toList()
      ..sort((a, b) {
        final first = a.publishedAt ?? a.updatedAt;
        final second = b.publishedAt ?? b.updatedAt;
        return second.compareTo(first);
      });

    final total = results.length;
    final passed = results.where((result) => result.isPassed).length;
    final failed = total - passed;

    final average = total == 0
        ? 0.0
        : results
                .map((result) => result.percentage)
                .fold<double>(0, (sum, value) => sum + value) /
            total;

    return ParentResultsSummary(
      results: List<ExamResultEntity>.unmodifiable(results),
      latestResult: results.isEmpty ? null : results.first,
      totalPublishedResults: total,
      averagePercentage: average,
      passedResults: passed,
      failedResults: failed,
    );
  }
}
'@

WriteText $di @'
import 'package:get_it/get_it.dart';

import '../exams/domain/repositories/exam_result_repository.dart';
import 'data/services/parent_results_service_impl.dart';
import 'domain/services/parent_results_service.dart';

void registerParentResultsDependencies(GetIt sl) {
  if (!sl.isRegistered<ParentResultsService>()) {
    sl.registerLazySingleton<ParentResultsService>(
      () => ParentResultsServiceImpl(
        sl<ExamResultRepository>(),
      ),
    );
  }
}
'@

$text=[IO.File]::ReadAllText((Full $sl)).Replace("`r`n","`n")

$import="import '../../features/parent_portal/parent_results_di.dart';"
if(-not $text.Contains($import)){
  $idx=$text.IndexOf('import ')
  if($idx -lt 0){throw 'Import anchor not found.'}
  $text=$text.Insert($idx,"$import`n")
}

$call='registerParentResultsDependencies(sl);'
if(-not $text.Contains($call)){
  $anchor='Future<void> setupServiceLocator() async {'
  $idx=$text.IndexOf($anchor)
  if($idx -lt 0){throw 'setupServiceLocator anchor not found.'}
  $text=$text.Insert($idx+$anchor.Length,"`n  $call")
}

WriteText $sl $text

dart format $summary $service $impl $di $sl
if($LASTEXITCODE -ne 0){throw "FORMAT ERROR. Backup: $backup"}

flutter analyze lib/features/parent_portal lib/features/exams $sl --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){throw "ANALYZE ERROR. Backup: $backup"}

Write-Host ''
Write-Host 'Parent Results Phase 2D Part 1 completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
