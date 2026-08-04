[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\timeline_phase2a11_$stamp"

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

$widget='lib/features/timeline/presentation/widgets/recent_timeline_card.dart'
$dashboard='lib/features/parent_portal/presentation/pages/parent_portal_dashboard_page.dart'

foreach($f in @($widget,$dashboard)){BackupFile $f}

WriteText $widget @'
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/timeline_event_entity.dart';
import '../../domain/services/timeline_service.dart';
import '../pages/timeline_page.dart';
import 'timeline_event_icon.dart';

class RecentTimelineCard extends StatefulWidget {
  const RecentTimelineCard({
    super.key,
    required this.studentId,
    this.limit = 5,
  });

  final String studentId;
  final int limit;

  @override
  State<RecentTimelineCard> createState() =>
      _RecentTimelineCardState();
}

class _RecentTimelineCardState
    extends State<RecentTimelineCard> {
  final TimelineService _service = sl<TimelineService>();

  List<TimelineEventEntity> _events =
      const <TimelineEventEntity>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(
    covariant RecentTimelineCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.studentId != widget.studentId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final values = await _service.loadStudentTimeline(
      studentId: widget.studentId,
    );

    if (!mounted) return;

    setState(() {
      _events = values.take(widget.limit).toList(growable: false);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Timeline',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => TimelinePage(
                          studentId: widget.studentId,
                        ),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_events.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No recent timeline activity.',
                  ),
                ),
              )
            else
              for (final event in _events)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: TimelineEventIcon(type: event.type),
                  title: Text(event.title),
                  subtitle: Text(event.description),
                ),
          ],
        ),
      ),
    );
  }
}
'@

$text=[IO.File]::ReadAllText((Full $dashboard)).Replace("`r`n","`n")

$import="import '../../../timeline/presentation/widgets/recent_timeline_card.dart';"
if(-not $text.Contains($import)){
  $anchor="import '../../../timeline/presentation/pages/timeline_page.dart';"
  if(-not $text.Contains($anchor)){throw 'Timeline page import anchor not found.'}
  $text=$text.Replace($anchor,"$anchor`n$import")
}

$anchor2='          const SizedBox(height: 18),`n          _PortalModulesGrid(parent: widget.parent, student: selectedStudent!),'
if(-not $text.Contains($anchor2)){
  $anchor2="          const SizedBox(height: 18),`n          _PortalModulesGrid(parent: widget.parent, student: selectedStudent!),"
}

$replacement="          const SizedBox(height: 18),`n          RecentTimelineCard(studentId: selectedStudent.id),`n          const SizedBox(height: 18),`n          _PortalModulesGrid(parent: widget.parent, student: selectedStudent),"

if(-not $text.Contains($anchor2)){throw 'Dashboard timeline insertion anchor not found.'}

$text=$text.Replace($anchor2,$replacement)
WriteText $dashboard $text

dart format $widget $dashboard
if($LASTEXITCODE -ne 0){throw "FORMAT ERROR. Backup: $backup"}

flutter analyze lib/features/timeline lib/features/parent_portal --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){throw "ANALYZE ERROR. Backup: $backup"}

Write-Host ''
Write-Host 'Timeline Phase 2A.11 completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
