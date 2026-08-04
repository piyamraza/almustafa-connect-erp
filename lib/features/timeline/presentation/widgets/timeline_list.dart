import 'package:flutter/material.dart';

import '../../domain/entities/timeline_event_entity.dart';
import 'timeline_empty_state.dart';
import 'timeline_event_icon.dart';

class TimelineList extends StatelessWidget {
  const TimelineList({super.key, required this.events});

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
      separatorBuilder: (_, _) => const SizedBox(height: 8),
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
