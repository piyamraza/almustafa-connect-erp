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
  State<RecentTimelineCard> createState() => _RecentTimelineCardState();
}

class _RecentTimelineCardState extends State<RecentTimelineCard> {
  final TimelineService _service = sl<TimelineService>();

  List<TimelineEventEntity> _events = const <TimelineEventEntity>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RecentTimelineCard oldWidget) {
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            TimelinePage(studentId: widget.studentId),
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
                child: Center(child: Text('No recent timeline activity.')),
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
