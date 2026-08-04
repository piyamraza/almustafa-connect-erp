import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../../data/repositories/teacher_duty_repository.dart';
import '../../domain/entities/teacher_duty_entities.dart';

class SubstituteDutyManagementPage extends StatefulWidget {
  const SubstituteDutyManagementPage({super.key});

  @override
  State<SubstituteDutyManagementPage> createState() =>
      _SubstituteDutyManagementPageState();
}

class _SubstituteDutyManagementPageState
    extends State<SubstituteDutyManagementPage> {
  final TeacherDutyRepository _repository = TeacherDutyRepository();

  late Future<_AdminDutyData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AdminDutyData> _load() async {
    final values = await Future.wait<Object>([
      _repository.getLeaveRequests(),
      _repository.getDuties(),
    ]);

    return _AdminDutyData(
      leaves: values[0] as List<TeacherLeaveRequestEntity>,
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
      appBar: AppBar(title: const Text('Substitute Duties')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAssignDialog,
        icon: const Icon(Icons.add),
        label: const Text('Assign Duty'),
      ),
      body: FutureBuilder<_AdminDutyData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  'Leave Requests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (data.leaves.isEmpty)
                  const Card(
                    child: ListTile(title: Text('No leave requests found.')),
                  ),
                ...data.leaves.map(
                  (leave) => Card(
                    child: ListTile(
                      title: Text(leave.teacherEmail),
                      subtitle: Text(
                        '${_date(leave.fromDate)} to '
                        '${_date(leave.toDate)}\n'
                        '${leave.reason}',
                      ),
                      isThreeLine: true,
                      trailing: leave.status == TeacherLeaveStatus.pending
                          ? Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Approve',
                                  onPressed: () async {
                                    await _repository.updateLeaveStatus(
                                      id: leave.id,
                                      status: TeacherLeaveStatus.approved,
                                    );
                                    await _refresh();
                                  },
                                  icon: const Icon(Icons.check_circle_outline),
                                ),
                                IconButton(
                                  tooltip: 'Reject',
                                  onPressed: () async {
                                    await _repository.updateLeaveStatus(
                                      id: leave.id,
                                      status: TeacherLeaveStatus.rejected,
                                    );
                                    await _refresh();
                                  },
                                  icon: const Icon(Icons.cancel_outlined),
                                ),
                              ],
                            )
                          : Chip(label: Text(leave.status.name)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Assigned Substitute Duties',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (data.duties.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('No substitute duties assigned.'),
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
                        '${duty.originalTeacherEmail} â†’ '
                        '${duty.substituteTeacherEmail}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'Cancel Duty',
                        onPressed: () async {
                          await _repository.cancelDuty(duty.id);
                          await _refresh();
                        },
                        icon: const Icon(Icons.delete_outline),
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

  Future<void> _showAssignDialog() async {
    List<TeacherEntity> teachers;
    try {
      teachers = await sl<TeacherRepository>().getTeachers();
      teachers = teachers.where((teacher) => teacher.isActive).toList()
        ..sort(
          (first, second) => first.fullName.toLowerCase().compareTo(
            second.fullName.toLowerCase(),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Teachers could not be loaded: $error')),
      );
      return;
    }
    if (!mounted) return;

    final originalController = TextEditingController();
    final substituteController = TextEditingController();
    final periodController = TextEditingController();
    final classController = TextEditingController();
    final sectionController = TextEditingController();
    final subjectController = TextEditingController();
    final roomController = TextEditingController();
    final notesController = TextEditingController();
    TeacherEntity? originalTeacher;
    TeacherEntity? substituteTeacher;
    var date = DateTime.now();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Substitute Duty'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: originalController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Absent Teacher',
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    onTap: () async {
                      final selected = await _selectTeacher(
                        dialogContext,
                        teachers,
                        title: 'Select Absent Teacher',
                        selected: originalTeacher,
                      );
                      if (selected != null) {
                        setDialogState(() {
                          originalTeacher = selected;
                          originalController.text = selected.fullName;
                          if (substituteTeacher?.id == selected.id) {
                            substituteTeacher = null;
                            substituteController.clear();
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: substituteController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Substitute Teacher',
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    onTap: () async {
                      final selected = await _selectTeacher(
                        dialogContext,
                        teachers,
                        title: 'Select Substitute Teacher',
                        selected: substituteTeacher,
                        excludedTeacherId: originalTeacher?.id,
                      );
                      if (selected != null) {
                        setDialogState(() {
                          substituteTeacher = selected;
                          substituteController.text = selected.fullName;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Duty Date'),
                    subtitle: Text(_date(date)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: date,
                      );
                      if (selected != null) {
                        setDialogState(() => date = selected);
                      }
                    },
                  ),
                  TextField(
                    controller: periodController,
                    decoration: const InputDecoration(
                      labelText: 'Period / Time',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: classController,
                    decoration: const InputDecoration(labelText: 'Class'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: sectionController,
                    decoration: const InputDecoration(labelText: 'Section'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: roomController,
                    decoration: const InputDecoration(
                      labelText: 'Room (optional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (save == true && mounted) {
      if (originalTeacher == null ||
          substituteTeacher == null ||
          periodController.text.trim().isEmpty ||
          classController.text.trim().isEmpty ||
          subjectController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Absent teacher, substitute teacher, period, class and subject are required.',
            ),
          ),
        );
      } else {
        final now = DateTime.now();

        await _repository.assignDuty(
          SubstituteDutyEntity(
            id: 'duty_${now.microsecondsSinceEpoch}',
            originalTeacherEmail: _teacherIdentifier(originalTeacher!),
            substituteTeacherEmail: _teacherIdentifier(substituteTeacher!),
            dutyDate: date,
            periodLabel: periodController.text.trim(),
            className: classController.text.trim(),
            sectionName: sectionController.text.trim(),
            subjectName: subjectController.text.trim(),
            room: roomController.text.trim(),
            notes: notesController.text.trim(),
            isActive: true,
            createdAt: now,
          ),
        );

        await _refresh();
      }
    }

    originalController.dispose();
    substituteController.dispose();
    periodController.dispose();
    classController.dispose();
    sectionController.dispose();
    subjectController.dispose();
    roomController.dispose();
    notesController.dispose();
  }

  Future<TeacherEntity?> _selectTeacher(
    BuildContext context,
    List<TeacherEntity> teachers, {
    required String title,
    TeacherEntity? selected,
    String? excludedTeacherId,
  }) {
    final searchController = TextEditingController();
    var query = '';
    return showDialog<TeacherEntity>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = teachers
              .where((teacher) {
                if (teacher.id == excludedTeacherId) return false;
                final searchText = [
                  teacher.fullName,
                  teacher.employeeId,
                  teacher.email,
                  teacher.designation,
                ].join(' ').toLowerCase();
                return searchText.contains(query.trim().toLowerCase());
              })
              .toList(growable: false);

          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 480,
              height: 460,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Search teacher by name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setDialogState(() => query = value),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No teacher found.'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final teacher = filtered[index];
                              return ListTile(
                                selected: teacher.id == selected?.id,
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person_outline),
                                ),
                                title: Text(teacher.fullName),
                                subtitle: Text(
                                  teacher.email.trim().isNotEmpty
                                      ? '${teacher.employeeId} • ${teacher.email}'
                                      : '${teacher.employeeId} • Email missing',
                                ),
                                onTap: () =>
                                    Navigator.pop(dialogContext, teacher),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(searchController.dispose);
  }

  static String _teacherIdentifier(TeacherEntity teacher) {
    final email = teacher.email.trim();
    return email.isNotEmpty ? email : teacher.id;
  }

  static String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year}';
  }
}

class _AdminDutyData {
  const _AdminDutyData({required this.leaves, required this.duties});

  final List<TeacherLeaveRequestEntity> leaves;
  final List<SubstituteDutyEntity> duties;
}
