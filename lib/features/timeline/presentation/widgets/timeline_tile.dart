import 'package:flutter/material.dart';
import '../../domain/entities/timeline_event_entity.dart';

class TimelineTile extends StatelessWidget {
  const TimelineTile({super.key, required this.event});

  final TimelineEventEntity event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.timeline),
        title: Text(event.title),
        subtitle: Text(event.description),
        trailing: Text('${event.occurredAt.day}/${event.occurredAt.month}'),
      ),
    );
  }
}
