[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
if(-not(Test-Path (Join-Path $root 'pubspec.yaml'))){
    throw 'Run this script from project root.'
}

$files=@{
'lib/features/timeline/presentation/widgets/timeline_event_icon.dart'=@'
import 'package:flutter/material.dart';

import '../../domain/entities/timeline_event_entity.dart';

class TimelineEventIcon extends StatelessWidget {
  const TimelineEventIcon({
    super.key,
    required this.type,
  });

  final TimelineEventType type;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      TimelineEventType.attendance => Icons.fact_check_outlined,
      TimelineEventType.homework => Icons.menu_book_outlined,
      TimelineEventType.fee => Icons.payments_outlined,
      TimelineEventType.result => Icons.grade_outlined,
      TimelineEventType.notice => Icons.campaign_outlined,
      TimelineEventType.message => Icons.message_outlined,
      TimelineEventType.leave => Icons.event_available_outlined,
      TimelineEventType.remark => Icons.comment_outlined,
      TimelineEventType.birthday => Icons.cake_outlined,
      TimelineEventType.schoolEvent => Icons.event_outlined,
      TimelineEventType.general => Icons.timeline,
    };

    return CircleAvatar(
      child: Icon(icon),
    );
  }
}
'@

'lib/features/timeline/presentation/widgets/timeline_empty_state.dart'=@'
import 'package:flutter/material.dart';

class TimelineEmptyState extends StatelessWidget {
  const TimelineEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline, size: 52),
            SizedBox(height: 14),
            Text(
              'No timeline activity is available yet.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
'@

'lib/features/timeline/presentation/widgets/timeline_list.dart'=@'
import 'package:flutter/material.dart';

import '../../domain/entities/timeline_event_entity.dart';
import 'timeline_empty_state.dart';
import 'timeline_event_icon.dart';

class TimelineList extends StatelessWidget {
  const TimelineList({
    super.key,
    required this.events,
  });

  final List<TimelineEventEntity> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const TimelineEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final event = events[index];

        return Card(
          child: ListTile(
            leading: TimelineEventIcon(type: event.type),
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.description.trim().isNotEmpty)
                  Text(event.description),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(event.occurredAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year}  $hour:$minute';
  }
}
'@
}

foreach($item in $files.GetEnumerator()){
    $full=Join-Path $root $item.Key
    New-Item -ItemType Directory -Force -Path (Split-Path $full -Parent)|Out-Null
    [IO.File]::WriteAllText(
        $full,
        $item.Value.Replace("`r`n","`n"),
        (New-Object System.Text.UTF8Encoding($false))
    )
}

dart format `
  lib/features/timeline/presentation/widgets/timeline_event_icon.dart `
  lib/features/timeline/presentation/widgets/timeline_empty_state.dart `
  lib/features/timeline/presentation/widgets/timeline_list.dart

if($LASTEXITCODE -ne 0){throw 'Format failed.'}

flutter analyze lib/features/timeline --no-fatal-infos --no-fatal-warnings

if($LASTEXITCODE -ne 0){throw 'Analyze failed.'}

Write-Host ''
Write-Host 'Timeline Phase 2A.8 completed successfully.' -ForegroundColor Green
