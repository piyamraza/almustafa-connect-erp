[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
if(-not(Test-Path (Join-Path $root 'pubspec.yaml'))){
    throw 'Run from project root.'
}

$target='lib/features/timeline/presentation/pages/timeline_page.dart'
$full=Join-Path $root $target

New-Item -ItemType Directory -Force -Path (Split-Path $full -Parent)|Out-Null

@'
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/services/timeline_service.dart';
import '../../domain/entities/timeline_event_entity.dart';
import '../widgets/timeline_list.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  final TimelineService _service = sl<TimelineService>();
  List<TimelineEventEntity> _events = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.loadStudentTimeline(studentId: '');
    if (!mounted) return;
    setState(() {
      _events = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: TimelineList(events: _events),
              ),
            ),
    );
  }
}
'@ | Set-Content $full -Encoding utf8

dart format $target
if($LASTEXITCODE -ne 0){throw 'Format failed.'}

flutter analyze $target --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){throw 'Analyze failed.'}

Write-Host 'Timeline Phase 2A.9 completed.'
