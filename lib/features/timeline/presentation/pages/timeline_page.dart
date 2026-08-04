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

  List<TimelineEventEntity> _events = const <TimelineEventEntity>[];
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
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: TimelineList(events: _events),
              ),
            ),
    );
  }
}
