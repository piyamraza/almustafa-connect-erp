[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
if(-not(Test-Path (Join-Path $root 'pubspec.yaml'))){
    throw 'Run this script from project root.'
}

$target='lib/features/timeline/presentation/widgets/timeline_tile.dart'
$full=Join-Path $root $target

New-Item -ItemType Directory -Force -Path (Split-Path $full -Parent) | Out-Null

@'
import 'package:flutter/material.dart';
import '../../domain/entities/timeline_event_entity.dart';

class TimelineTile extends StatelessWidget {
  const TimelineTile({
    super.key,
    required this.event,
  });

  final TimelineEventEntity event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.timeline),
        title: Text(event.title),
        subtitle: Text(event.description),
        trailing: Text(
          '${event.occurredAt.day}/${event.occurredAt.month}',
        ),
      ),
    );
  }
}
'@ | Set-Content $full -Encoding utf8

dart format $target
if($LASTEXITCODE -ne 0){ throw 'Format failed.' }

flutter analyze $target --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){ throw 'Analyze failed.' }

Write-Host ''
Write-Host 'Timeline Phase 2A.7 completed successfully.' -ForegroundColor Green
