import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../data/repositories/teacher_duty_repository.dart';
import '../../domain/entities/teacher_duty_entities.dart';

class TeacherLeaveDutiesPage extends StatefulWidget {
  const TeacherLeaveDutiesPage({super.key});

  @override
  State<TeacherLeaveDutiesPage> createState() =>
      _TeacherLeaveDutiesPageState();
}

class _TeacherLeaveDutiesPageState
    extends State<TeacherLeaveDutiesPage> {
  final TeacherDutyRepository _repository =
      TeacherDutyRepository();

  late Future<_TeacherDutyData> _future;

  String get _email =>
      sl<AccessControlService>().currentUserEmail ?? '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TeacherDutyData> _load() async {
    final values = await Future.wait<Object>([
      _repository.getLeaveRequests(
        teacherEmail: _email,
      ),
      _repository.getDuties(
        substituteTeacherEmail: _email,
      ),
    ]);

    return _TeacherDutyData(
      leaveRequests:
          values[0] as List<TeacherLeaveRequestEntity>,
      duties: values[1] as List<SubstituteDutyEntity>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave & Substitute Duties'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLeaveDialog,
        icon: const Icon(Icons.add),
        label: const Text('Apply Leave'),
      ),
      body: FutureBuilder<_TeacherDutyData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  'Temporary Duties',
                  style:
                      Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (data.duties.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text(
                        'No substitute duties assigned.',
                      ),
                    ),
                  ),
                ...data.duties.map(
                  (duty) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.swap_horiz),
                      ),
                      title: Text(
                        '${duty.className}-${duty.sectionName} '
                        '${duty.subjectName}',
                      ),
                      subtitle: Text(
                        '${_date(duty.dutyDate)} | '
                        '${duty.periodLabel}\n'
                        'Original teacher: '
                        '${duty.originalTeacherEmail}'
                        '${duty.room.isEmpty ? '' : '\nRoom: ${duty.room}'}',
                      ),
                      isThreeLine: true,
                      trailing: const Chip(
                        label: Text('Substitute'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'My Leave Requests',
                  style:
                      Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (data.leaveRequests.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text(
                        'No leave requests submitted.',
                      ),
                    ),
                  ),
                ...data.leaveRequests.map(
                  (leave) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child:
                            Icon(Icons.event_busy_outlined),
                      ),
                      title: Text(
                        '${_date(leave.fromDate)} to '
                        '${_date(leave.toDate)}',
                      ),
                      subtitle: Text(leave.reason),
                      trailing: Chip(
                        label: Text(leave.status.name),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showLeaveDialog() async {
    var fromDate = DateTime.now();
    var toDate = DateTime.now();
    final reasonController =
        TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) =>
            AlertDialog(
          title: const Text('Apply for Leave'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('From Date'),
                  subtitle: Text(_date(fromDate)),
                  trailing:
                      const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selected =
                        await showDatePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      initialDate: fromDate,
                    );
                    if (selected != null) {
                      setDialogState(
                        () => fromDate = selected,
                      );
                    }
                  },
                ),
                ListTile(
                  title: const Text('To Date'),
                  subtitle: Text(_date(toDate)),
                  trailing:
                      const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selected =
                        await showDatePicker(
                      context: context,
                      firstDate: fromDate,
                      lastDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      initialDate: toDate.isBefore(fromDate)
                          ? fromDate
                          : toDate,
                    );
                    if (selected != null) {
                      setDialogState(
                        () => toDate = selected,
                      );
                    }
                  },
                ),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (save == true && mounted) {
      if (_email.trim().isEmpty ||
          reasonController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Teacher email and reason are required.',
            ),
          ),
        );
      } else {
        await _repository.submitLeave(
          teacherEmail: _email,
          fromDate: fromDate,
          toDate: toDate,
          reason: reasonController.text,
        );
        await _refresh();
      }
    }

    reasonController.dispose();
  }

  static String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year}';
  }
}

class _TeacherDutyData {
  const _TeacherDutyData({
    required this.leaveRequests,
    required this.duties,
  });

  final List<TeacherLeaveRequestEntity> leaveRequests;
  final List<SubstituteDutyEntity> duties;
}