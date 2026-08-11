import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
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
      sl<TeacherRepository>().getTeachers(),
    ]);

    return _AdminDutyData(
      leaves: values[0] as List<TeacherLeaveRequestEntity>,
      duties: values[1] as List<SubstituteDutyEntity>,
      teachers: values[2] as List<TeacherEntity>,
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
        title: const Text('Substitute Duties'),
        actions: const [DashboardNavigationButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAssignDialog,
        icon: const Icon(Icons.add),
        label: const Text('Assign Duty'),
      ),
      body: FutureBuilder<_AdminDutyData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text('Unable to load substitute duties.'),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

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
                      title: Text(
                        _teacherName(data.teachers, leave.teacherEmail),
                      ),
                      subtitle: Text(
                        '${_date(leave.fromDate)} to ${_date(leave.toDate)}\n'
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
                ...data.duties.map((duty) {
                  final originalTeacherName = _teacherName(
                    data.teachers,
                    duty.originalTeacherEmail,
                  );
                  final substituteTeacherName = _teacherName(
                    data.teachers,
                    duty.substituteTeacherEmail,
                  );

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.swap_horiz),
                      ),
                      title: Text(
                        '${_classSectionLabel(duty.className, duty.sectionName)} '
                                '${duty.subjectName}'
                            .trim(),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_date(duty.dutyDate)} | '
                              'Period ${duty.periodLabel}',
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                const Text(
                                  'Absent:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(originalTeacherName),
                                const Icon(Icons.arrow_forward, size: 16),
                                const Text(
                                  'Substitute:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(substituteTeacherName),
                              ],
                            ),
                            if (duty.room.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Room: ${duty.room.trim()}'),
                            ],
                            if (duty.notes.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Notes: ${duty.notes.trim()}'),
                            ],
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: 'Cancel Duty',
                        onPressed: () async {
                          await _repository.cancelDuty(duty.id);
                          await _refresh();
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  );
                }),
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
          (a, b) =>
              a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Teachers could not be loaded: $error')),
      );
      return;
    }

    if (!mounted) return;

    final roomController = TextEditingController();
    final notesController = TextEditingController();

    TeacherEntity? originalTeacher;
    TeacherEntity? substituteTeacher;
    DateTime date = DateTime.now();

    List<_TimetableSlot> availableSlots = [];
    List<_TimetableSlot> classSlots = [];
    List<_TimetableSlot> sectionSlots = [];
    List<_TimetableSlot> subjectSlots = [];

    String? selectedClassId;
    String? selectedClassName;
    String? selectedSectionId;
    String? selectedSectionName;
    String? selectedSubjectId;
    String? selectedSubjectName;
    String? selectedPeriodId;
    String? selectedPeriodLabel;

    bool loadingTimetable = false;
    String? timetableMessage;

    Future<void> loadTeacherDayTimetable(
      void Function(void Function()) setDialogState,
    ) async {
      if (originalTeacher == null) {
        setDialogState(() {
          availableSlots = [];
          classSlots = [];
          sectionSlots = [];
          subjectSlots = [];
          timetableMessage = null;
        });
        return;
      }

      setDialogState(() {
        loadingTimetable = true;
        timetableMessage = null;
        selectedClassId = null;
        selectedClassName = null;
        selectedSectionId = null;
        selectedSectionName = null;
        selectedSubjectId = null;
        selectedSubjectName = null;
        selectedPeriodId = null;
        selectedPeriodLabel = null;
      });

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('timetable_entries')
            .where('teacherId', isEqualTo: originalTeacher!.id)
            .get();

        final slots =
            snapshot.docs
                .map((doc) => _TimetableSlot.fromMap(doc.id, doc.data()))
                .where((slot) => slot.weekday == date.weekday)
                .toList()
              ..sort((a, b) => a.periodOrder.compareTo(b.periodOrder));

        setDialogState(() {
          availableSlots = slots;
          classSlots = _uniqueBy(slots, (item) => item.classId);
          sectionSlots = [];
          subjectSlots = [];
          loadingTimetable = false;
          timetableMessage = slots.isEmpty
              ? 'No timetable periods found for this teacher on ${_weekdayName(date.weekday)}.'
              : null;
        });
      } catch (error) {
        setDialogState(() {
          availableSlots = [];
          classSlots = [];
          sectionSlots = [];
          subjectSlots = [];
          loadingTimetable = false;
          timetableMessage = 'Timetable could not be loaded: $error';
        });
      }
    }

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          void rebuildSections() {
            final values = availableSlots
                .where((item) => item.classId == selectedClassId)
                .toList();

            sectionSlots = _uniqueBy(values, (item) => item.sectionId);
          }

          void rebuildSubjects() {
            final values = availableSlots
                .where(
                  (item) =>
                      item.classId == selectedClassId &&
                      item.sectionId == selectedSectionId,
                )
                .toList();

            subjectSlots = _uniqueBy(values, (item) => item.subjectId);
          }

          List<_TimetableSlot> periodSlots() {
            return availableSlots
                .where(
                  (item) =>
                      item.classId == selectedClassId &&
                      item.sectionId == selectedSectionId &&
                      item.subjectId == selectedSubjectId,
                )
                .toList()
              ..sort((a, b) => a.periodOrder.compareTo(b.periodOrder));
          }

          return AlertDialog(
            title: const Text('Assign Substitute Duty'),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TeacherPickerField(
                      label: 'Absent Teacher',
                      teacher: originalTeacher,
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
                            if (substituteTeacher?.id == selected.id) {
                              substituteTeacher = null;
                            }
                          });
                          await loadTeacherDayTimetable(setDialogState);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _TeacherPickerField(
                      label: 'Substitute Teacher',
                      teacher: substituteTeacher,
                      onTap: () async {
                        final selected = await _selectTeacher(
                          dialogContext,
                          teachers,
                          title: 'Select Substitute Teacher',
                          selected: substituteTeacher,
                          excludedTeacherId: originalTeacher?.id,
                        );

                        if (selected != null) {
                          setDialogState(() => substituteTeacher = selected);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Duty Date'),
                      subtitle: Text(
                        '${_date(date)} (${_weekdayName(date.weekday)})',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final now = DateTime.now();
                        final selected = await showDatePicker(
                          context: context,
                          firstDate: now.subtract(const Duration(days: 30)),
                          lastDate: now.add(const Duration(days: 365)),
                          initialDate: date,
                        );

                        if (selected != null) {
                          setDialogState(() => date = selected);
                          await loadTeacherDayTimetable(setDialogState);
                        }
                      },
                    ),
                    if (loadingTimetable) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                    ],
                    if (timetableMessage != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          timetableMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    DropdownButtonFormField<String>(
                      initialValue: selectedClassId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                      ),
                      items: classSlots
                          .map(
                            (slot) => DropdownMenuItem(
                              value: slot.classId,
                              child: Text(slot.className),
                            ),
                          )
                          .toList(),
                      onChanged: classSlots.isEmpty
                          ? null
                          : (value) {
                              final slot = classSlots.firstWhere(
                                (item) => item.classId == value,
                              );
                              setDialogState(() {
                                selectedClassId = slot.classId;
                                selectedClassName = slot.className;
                                selectedSectionId = null;
                                selectedSectionName = null;
                                selectedSubjectId = null;
                                selectedSubjectName = null;
                                selectedPeriodId = null;
                                selectedPeriodLabel = null;
                                rebuildSections();
                                subjectSlots = [];
                              });
                            },
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      initialValue: selectedSectionId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Section',
                        border: OutlineInputBorder(),
                      ),
                      items: sectionSlots
                          .map(
                            (slot) => DropdownMenuItem(
                              value: slot.sectionId,
                              child: Text(slot.sectionName),
                            ),
                          )
                          .toList(),
                      onChanged: sectionSlots.isEmpty
                          ? null
                          : (value) {
                              final slot = sectionSlots.firstWhere(
                                (item) => item.sectionId == value,
                              );
                              setDialogState(() {
                                selectedSectionId = slot.sectionId;
                                selectedSectionName = slot.sectionName;
                                selectedSubjectId = null;
                                selectedSubjectName = null;
                                selectedPeriodId = null;
                                selectedPeriodLabel = null;
                                rebuildSubjects();
                              });
                            },
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      initialValue: selectedSubjectId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                      items: subjectSlots
                          .map(
                            (slot) => DropdownMenuItem(
                              value: slot.subjectId,
                              child: Text(slot.subjectName),
                            ),
                          )
                          .toList(),
                      onChanged: subjectSlots.isEmpty
                          ? null
                          : (value) {
                              final slot = subjectSlots.firstWhere(
                                (item) => item.subjectId == value,
                              );
                              setDialogState(() {
                                selectedSubjectId = slot.subjectId;
                                selectedSubjectName = slot.subjectName;
                                selectedPeriodId = null;
                                selectedPeriodLabel = null;
                              });
                            },
                    ),
                    const SizedBox(height: 10),

                    Builder(
                      builder: (context) {
                        final periods = periodSlots();
                        return DropdownButtonFormField<String>(
                          initialValue: selectedPeriodId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Period / Time',
                            border: OutlineInputBorder(),
                          ),
                          items: periods
                              .map(
                                (slot) => DropdownMenuItem(
                                  value: slot.periodId,
                                  child: Text(slot.periodLabel),
                                ),
                              )
                              .toList(),
                          onChanged: periods.isEmpty
                              ? null
                              : (value) {
                                  final slot = periods.firstWhere(
                                    (item) => item.periodId == value,
                                  );
                                  setDialogState(() {
                                    selectedPeriodId = slot.periodId;
                                    selectedPeriodLabel = slot.periodLabel;
                                  });
                                },
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: roomController,
                      decoration: const InputDecoration(
                        labelText: 'Room (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
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
                onPressed: () {
                  if (originalTeacher == null ||
                      substituteTeacher == null ||
                      selectedClassId == null ||
                      selectedSectionId == null ||
                      selectedSubjectId == null ||
                      selectedPeriodId == null) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please select absent teacher, substitute teacher, '
                          'class, section, subject and period.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Assign'),
              ),
            ],
          );
        },
      ),
    );

    if (save == true && mounted) {
      final now = DateTime.now();

      await _repository.assignDuty(
        SubstituteDutyEntity(
          id: 'duty_${now.microsecondsSinceEpoch}',
          originalTeacherEmail: _teacherIdentifier(originalTeacher!),
          substituteTeacherEmail: _teacherIdentifier(substituteTeacher!),
          dutyDate: date,
          periodLabel: selectedPeriodLabel ?? '',
          className: selectedClassName ?? '',
          sectionName: selectedSectionName ?? '',
          subjectName: selectedSubjectName ?? '',
          room: roomController.text.trim(),
          notes: notesController.text.trim(),
          isActive: true,
          createdAt: now,
        ),
      );

      await _refresh();
    }

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
          final filtered = teachers.where((teacher) {
            if (teacher.id == excludedTeacherId) return false;

            final searchText = [
              teacher.fullName,
              teacher.employeeId,
              teacher.email,
              teacher.designation,
            ].join(' ').toLowerCase();

            return searchText.contains(query.trim().toLowerCase());
          }).toList();

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
                    onChanged: (value) {
                      setDialogState(() => query = value);
                    },
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
                                      : '${teacher.employeeId} • ${teacher.designation}',
                                ),
                                onTap: () {
                                  Navigator.pop(dialogContext, teacher);
                                },
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

  static List<_TimetableSlot> _uniqueBy(
    List<_TimetableSlot> values,
    String Function(_TimetableSlot item) key,
  ) {
    final seen = <String>{};
    final result = <_TimetableSlot>[];

    for (final item in values) {
      final value = key(item);
      if (value.isNotEmpty && seen.add(value)) {
        result.add(item);
      }
    }

    return result;
  }

  static String _teacherName(List<TeacherEntity> teachers, String identifier) {
    final value = identifier.trim().toLowerCase();

    if (value.isEmpty) return 'Unknown Teacher';

    for (final teacher in teachers) {
      final email = teacher.email.trim().toLowerCase();
      final id = teacher.id.trim().toLowerCase();
      final employeeId = teacher.employeeId.trim().toLowerCase();

      if ((email.isNotEmpty && email == value) ||
          id == value ||
          (employeeId.isNotEmpty && employeeId == value)) {
        final name = teacher.fullName.trim();
        return name.isEmpty ? 'Unknown Teacher' : name;
      }
    }

    if (!identifier.contains('@')) return 'Teacher not found';
    return identifier.trim();
  }

  static String _teacherIdentifier(TeacherEntity teacher) {
    final email = teacher.email.trim();
    return email.isNotEmpty ? email : teacher.id;
  }

  static String _classSectionLabel(String className, String sectionName) {
    final classValue = className.trim();
    final sectionValue = sectionName.trim();

    if (classValue.isNotEmpty && sectionValue.isNotEmpty) {
      return '$classValue-$sectionValue';
    }
    if (classValue.isNotEmpty) return classValue;
    if (sectionValue.isNotEmpty) return sectionValue;
    return '';
  }

  static String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year}';
  }

  static String _weekdayName(int weekday) {
    const names = <int, String>{
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };
    return names[weekday] ?? '';
  }
}

class _TeacherPickerField extends StatelessWidget {
  const _TeacherPickerField({
    required this.label,
    required this.teacher,
    required this.onTap,
  });

  final String label;
  final TeacherEntity? teacher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          teacher?.fullName.trim().isNotEmpty == true
              ? teacher!.fullName
              : 'Select $label',
          style: TextStyle(
            color: teacher == null ? Theme.of(context).hintColor : null,
          ),
        ),
      ),
    );
  }
}

class _TimetableSlot {
  const _TimetableSlot({
    required this.id,
    required this.weekday,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.subjectId,
    required this.subjectName,
    required this.periodId,
    required this.periodLabel,
    required this.periodOrder,
  });

  factory _TimetableSlot.fromMap(String id, Map<String, dynamic> map) {
    return _TimetableSlot(
      id: id,
      weekday: (map['weekday'] as num?)?.toInt() ?? 0,
      classId: '${map['classId'] ?? ''}'.trim(),
      className: '${map['className'] ?? ''}'.trim(),
      sectionId: '${map['sectionId'] ?? ''}'.trim(),
      sectionName: '${map['sectionName'] ?? ''}'.trim(),
      subjectId: '${map['subjectId'] ?? ''}'.trim(),
      subjectName: '${map['subjectName'] ?? ''}'.trim(),
      periodId: '${map['periodId'] ?? ''}'.trim(),
      periodLabel: '${map['periodLabel'] ?? ''}'.trim(),
      periodOrder: (map['periodOrder'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final int weekday;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final String subjectId;
  final String subjectName;
  final String periodId;
  final String periodLabel;
  final int periodOrder;
}

class _AdminDutyData {
  const _AdminDutyData({
    required this.leaves,
    required this.duties,
    required this.teachers,
  });

  final List<TeacherLeaveRequestEntity> leaves;
  final List<SubstituteDutyEntity> duties;
  final List<TeacherEntity> teachers;
}
