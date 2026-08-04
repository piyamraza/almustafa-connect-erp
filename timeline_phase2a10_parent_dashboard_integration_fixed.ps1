[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\timeline_phase2a10_fixed_$stamp"

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
  [IO.File]::WriteAllText((Full $p),$t.Replace("`r`n","`n"),$utf8)
}

if(-not(Test-Path (Full 'pubspec.yaml'))){throw 'Run from project root.'}

$page='lib/features/timeline/presentation/pages/timeline_page.dart'
$dashboard='lib/features/parent_portal/presentation/pages/parent_portal_dashboard_page.dart'

foreach($f in @($page,$dashboard)){
  if(-not(Test-Path (Full $f))){throw "Required file not found: $f"}
  BackupFile $f
}

WriteText $page @'
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/timeline_event_entity.dart';
import '../../domain/services/timeline_service.dart';
import '../widgets/timeline_list.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({
    super.key,
    required this.studentId,
    this.title = 'Timeline',
  });

  final String studentId;
  final String title;

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  final TimelineService _service = sl<TimelineService>();

  List<TimelineEventEntity> _events =
      const <TimelineEventEntity>[];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.loadStudentTimeline(
        studentId: widget.studentId,
      );

      if (!mounted) return;

      setState(() {
        _events = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = error
            .toString()
            .replaceFirst('StateError: ', '')
            .replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: TimelineList(events: _events),
                  ),
                ),
    );
  }
}
'@

$text=[IO.File]::ReadAllText((Full $dashboard)).Replace("`r`n","`n")

$oldImport="import 'parent_timeline_page.dart';"
$newImport="import '../../../timeline/presentation/pages/timeline_page.dart';"

if($text.Contains($oldImport)){
  $text=$text.Replace($oldImport,$newImport)
}elseif(-not $text.Contains($newImport)){
  $anchor="import 'parent_notification_center_page.dart';"
  if(-not $text.Contains($anchor)){throw 'Dashboard import anchor not found.'}
  $text=$text.Replace($anchor,"$anchor`n$newImport")
}

$oldBlock=@'
                  if (module.$1 == 'Timeline') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentTimelinePage(
                          parent: parent,
                          student: student,
                        ),
                      ),
                    );
                    return;
                  }
'@

$newBlock=@'
                  if (module.$1 == 'Timeline') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => TimelinePage(
                          studentId: student.id,
                          title: '${student.fullName} Timeline',
                        ),
                      ),
                    );
                    return;
                  }
'@

if(-not $text.Contains($oldBlock)){
  throw 'Timeline navigation block not found in dashboard.'
}

$text=$text.Replace($oldBlock,$newBlock)
WriteText $dashboard $text

dart format $page $dashboard
if($LASTEXITCODE -ne 0){throw "FORMAT ERROR. Backup: $backup"}

flutter analyze lib/features/timeline lib/features/parent_portal --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){throw "ANALYZE ERROR. Backup: $backup"}

Write-Host ''
Write-Host 'Timeline Phase 2A.10 completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
