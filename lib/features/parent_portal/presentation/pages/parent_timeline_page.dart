import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../../domain/entities/parent_timeline_item_entity.dart';
import '../../domain/services/parent_timeline_service.dart';

class ParentTimelinePage extends StatefulWidget {
  const ParentTimelinePage({
    super.key,
    required this.parent,
    required this.student,
    this.academicSession = '2026-2027',
  });

  final ParentAccountEntity parent;
  final StudentEntity student;
  final String academicSession;

  @override
  State<ParentTimelinePage> createState() => _ParentTimelinePageState();
}

class _ParentTimelinePageState extends State<ParentTimelinePage> {
  late Future<List<ParentTimelineItemEntity>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = sl<ParentTimelineService>().loadTimeline(
      parent: widget.parent,
      student: widget.student,
      academicSession: widget.academicSession,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.fullName} - Timeline'),
        actions: [
          IconButton(
            onPressed: () => setState(_load),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<ParentTimelineItemEntity>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No recent activity found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Icon(_icon(item.category))),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.description}\n'
                    '${_date(item.eventDate)}',
                  ),
                  isThreeLine: true,
                  trailing: Chip(label: Text(item.status)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static IconData _icon(String category) => switch (category) {
    'Attendance' => Icons.fact_check_outlined,
    'Homework' => Icons.menu_book_outlined,
    'Fee' => Icons.payments_outlined,
    'Notice' => Icons.campaign_outlined,
    'Result' => Icons.grade_outlined,
    'Calendar' => Icons.event_outlined,
    _ => Icons.timeline,
  };

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
