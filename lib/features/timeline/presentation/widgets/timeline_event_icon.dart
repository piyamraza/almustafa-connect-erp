import 'package:flutter/material.dart';

import '../../domain/entities/timeline_event_entity.dart';

class TimelineEventIcon extends StatelessWidget {
  const TimelineEventIcon({super.key, required this.type});

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

    return CircleAvatar(child: Icon(icon));
  }
}
