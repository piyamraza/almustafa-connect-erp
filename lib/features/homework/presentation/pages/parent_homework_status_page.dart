import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/homework_submission_entity.dart';
import '../../domain/repositories/homework_submission_repository.dart';

class ParentHomeworkStatusPage extends StatefulWidget {
  const ParentHomeworkStatusPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  final String studentId;
  final String studentName;

  @override
  State<ParentHomeworkStatusPage> createState() =>
      _ParentHomeworkStatusPageState();
}

class _ParentHomeworkStatusPageState extends State<ParentHomeworkStatusPage> {
  List<HomeworkSubmissionEntity> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await sl<HomeworkSubmissionRepository>().getSubmissions(
      studentId: widget.studentId,
    );
    if (!mounted) return;
    setState(() {
      _items = values;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Homework Status')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.studentName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in _items)
                  Card(
                    child: ListTile(
                      title: Text(item.status.name.toUpperCase()),
                      subtitle: Text(
                        item.teacherRemarks.isEmpty
                            ? 'No teacher remarks yet.'
                            : item.teacherRemarks,
                      ),
                      trailing: item.marksAwarded == null
                          ? null
                          : Text(
                              '${item.marksAwarded}'
                              '${item.maxMarks == null ? '' : '/${item.maxMarks}'}',
                            ),
                    ),
                  ),
              ],
            ),
    );
  }
}
