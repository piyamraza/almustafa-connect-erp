[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\teacher_portal_phase2_$stamp"

function Full([string]$Path) { Join-Path $root $Path }

function ReadText([string]$Path) {
  [IO.File]::ReadAllText((Full $Path))
}

function WriteText([string]$Path,[string]$Text) {
  $full = Full $Path
  $dir = Split-Path $full -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  [IO.File]::WriteAllText(
    $full,
    $Text.Replace("`r`n","`n"),
    $utf8
  )
}

function BackupFile([string]$Path) {
  $source = Full $Path
  if (-not (Test-Path $source)) { return }

  $target = Join-Path $backup $Path
  $dir = Split-Path $target -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  Copy-Item $source $target -Force
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run from Flutter project root.'
}

$teacherDashboard =
  'lib/features/teacher_portal/presentation/pages/teacher_portal_dashboard_page.dart'
$sidebar =
  'lib/features/dashboard/presentation/widgets/sidebar.dart'

foreach ($path in @($teacherDashboard, $sidebar)) {
  if (-not (Test-Path (Full $path))) {
    throw "REQUIRED FILE ERROR: $path"
  }
}

$entity =
  'lib/features/teacher_portal/domain/entities/teacher_duty_entities.dart'

if (Test-Path (Full $entity)) {
  throw 'EXISTING FILE ERROR: Teacher Portal Phase 2 appears installed.'
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
BackupFile $teacherDashboard
BackupFile $sidebar

WriteText $entity @'
import 'package:equatable/equatable.dart';

enum TeacherLeaveStatus {
  pending,
  approved,
  rejected,
}

class TeacherLeaveRequestEntity extends Equatable {
  const TeacherLeaveRequestEntity({
    required this.id,
    required this.teacherEmail,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String teacherEmail;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final TeacherLeaveStatus status;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        teacherEmail,
        fromDate,
        toDate,
        reason,
        status,
        createdAt,
      ];
}

class SubstituteDutyEntity extends Equatable {
  const SubstituteDutyEntity({
    required this.id,
    required this.originalTeacherEmail,
    required this.substituteTeacherEmail,
    required this.dutyDate,
    required this.periodLabel,
    required this.className,
    required this.sectionName,
    required this.subjectName,
    required this.room,
    required this.notes,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String originalTeacherEmail;
  final String substituteTeacherEmail;
  final DateTime dutyDate;
  final String periodLabel;
  final String className;
  final String sectionName;
  final String subjectName;
  final String room;
  final String notes;
  final bool isActive;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        originalTeacherEmail,
        substituteTeacherEmail,
        dutyDate,
        periodLabel,
        className,
        sectionName,
        subjectName,
        room,
        notes,
        isActive,
        createdAt,
      ];
}
'@

WriteText 'lib/features/teacher_portal/data/repositories/teacher_duty_repository.dart' @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/teacher_duty_entities.dart';

class TeacherDutyRepository {
  TeacherDutyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String leaveCollection = 'teacher_leave_requests';
  static const String dutyCollection = 'teacher_substitute_duties';

  final FirebaseFirestore _firestore;

  Future<List<TeacherLeaveRequestEntity>> getLeaveRequests({
    String? teacherEmail,
  }) async {
    final snapshot =
        await _firestore.collection(leaveCollection).get();

    final values = snapshot.docs
        .map(
          (doc) => _leaveFromMap(
            doc.id,
            doc.data(),
          ),
        )
        .where(
          (item) =>
              teacherEmail == null ||
              item.teacherEmail.toLowerCase() ==
                  teacherEmail.toLowerCase(),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return values;
  }

  Future<void> submitLeave({
    required String teacherEmail,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    final now = DateTime.now();
    final id = 'leave_${now.microsecondsSinceEpoch}';

    await _firestore.collection(leaveCollection).doc(id).set({
      'id': id,
      'teacherEmail': teacherEmail.trim(),
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'reason': reason.trim(),
      'status': TeacherLeaveStatus.pending.name,
      'createdAt': Timestamp.fromDate(now),
    });
  }

  Future<void> updateLeaveStatus({
    required String id,
    required TeacherLeaveStatus status,
  }) {
    return _firestore.collection(leaveCollection).doc(id).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<List<SubstituteDutyEntity>> getDuties({
    String? substituteTeacherEmail,
    DateTime? date,
  }) async {
    final snapshot =
        await _firestore.collection(dutyCollection).get();

    final values = snapshot.docs
        .map(
          (doc) => _dutyFromMap(
            doc.id,
            doc.data(),
          ),
        )
        .where((item) {
          final emailMatches =
              substituteTeacherEmail == null ||
              item.substituteTeacherEmail.toLowerCase() ==
                  substituteTeacherEmail.toLowerCase();

          final dateMatches = date == null ||
              (item.dutyDate.year == date.year &&
                  item.dutyDate.month == date.month &&
                  item.dutyDate.day == date.day);

          return emailMatches && dateMatches && item.isActive;
        })
        .toList()
      ..sort((a, b) => a.dutyDate.compareTo(b.dutyDate));

    return values;
  }

  Future<void> assignDuty(SubstituteDutyEntity duty) {
    return _firestore.collection(dutyCollection).doc(duty.id).set({
      'id': duty.id,
      'originalTeacherEmail': duty.originalTeacherEmail,
      'substituteTeacherEmail': duty.substituteTeacherEmail,
      'dutyDate': Timestamp.fromDate(duty.dutyDate),
      'periodLabel': duty.periodLabel,
      'className': duty.className,
      'sectionName': duty.sectionName,
      'subjectName': duty.subjectName,
      'room': duty.room,
      'notes': duty.notes,
      'isActive': duty.isActive,
      'createdAt': Timestamp.fromDate(duty.createdAt),
    });
  }

  Future<void> cancelDuty(String id) {
    return _firestore.collection(dutyCollection).doc(id).update({
      'isActive': false,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  TeacherLeaveRequestEntity _leaveFromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return TeacherLeaveRequestEntity(
      id: id,
      teacherEmail: map['teacherEmail'] as String? ?? '',
      fromDate: _date(map['fromDate']),
      toDate: _date(map['toDate']),
      reason: map['reason'] as String? ?? '',
      status: TeacherLeaveStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => TeacherLeaveStatus.pending,
      ),
      createdAt: _date(map['createdAt']),
    );
  }

  SubstituteDutyEntity _dutyFromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return SubstituteDutyEntity(
      id: id,
      originalTeacherEmail:
          map['originalTeacherEmail'] as String? ?? '',
      substituteTeacherEmail:
          map['substituteTeacherEmail'] as String? ?? '',
      dutyDate: _date(map['dutyDate']),
      periodLabel: map['periodLabel'] as String? ?? '',
      className: map['className'] as String? ?? '',
      sectionName: map['sectionName'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      room: map['room'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _date(map['createdAt']),
    );
  }

  DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse('$value') ?? DateTime.now();
  }
}
'@

WriteText 'lib/features/teacher_portal/presentation/pages/teacher_leave_duties_page.dart' @'
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
'@

WriteText 'lib/features/teacher_portal/presentation/pages/substitute_duty_management_page.dart' @'
import 'package:flutter/material.dart';

import '../../data/repositories/teacher_duty_repository.dart';
import '../../domain/entities/teacher_duty_entities.dart';

class SubstituteDutyManagementPage
    extends StatefulWidget {
  const SubstituteDutyManagementPage({super.key});

  @override
  State<SubstituteDutyManagementPage> createState() =>
      _SubstituteDutyManagementPageState();
}

class _SubstituteDutyManagementPageState
    extends State<SubstituteDutyManagementPage> {
  final TeacherDutyRepository _repository =
      TeacherDutyRepository();

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
      leaves:
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
      appBar:
          AppBar(title: const Text('Substitute Duties')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAssignDialog,
        icon: const Icon(Icons.add),
        label: const Text('Assign Duty'),
      ),
      body: FutureBuilder<_AdminDutyData>(
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
                  'Leave Requests',
                  style:
                      Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (data.leaves.isEmpty)
                  const Card(
                    child: ListTile(
                      title:
                          Text('No leave requests found.'),
                    ),
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
                      trailing: leave.status ==
                              TeacherLeaveStatus.pending
                          ? Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Approve',
                                  onPressed: () async {
                                    await _repository
                                        .updateLeaveStatus(
                                      id: leave.id,
                                      status:
                                          TeacherLeaveStatus
                                              .approved,
                                    );
                                    await _refresh();
                                  },
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Reject',
                                  onPressed: () async {
                                    await _repository
                                        .updateLeaveStatus(
                                      id: leave.id,
                                      status:
                                          TeacherLeaveStatus
                                              .rejected,
                                    );
                                    await _refresh();
                                  },
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                  ),
                                ),
                              ],
                            )
                          : Chip(
                              label:
                                  Text(leave.status.name),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Assigned Substitute Duties',
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
                        '${duty.originalTeacherEmail} → '
                        '${duty.substituteTeacherEmail}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'Cancel Duty',
                        onPressed: () async {
                          await _repository
                              .cancelDuty(duty.id);
                          await _refresh();
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                        ),
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
    final originalController =
        TextEditingController();
    final substituteController =
        TextEditingController();
    final periodController =
        TextEditingController();
    final classController = TextEditingController();
    final sectionController =
        TextEditingController();
    final subjectController =
        TextEditingController();
    final roomController = TextEditingController();
    final notesController = TextEditingController();
    var date = DateTime.now();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) =>
            AlertDialog(
          title: const Text('Assign Substitute Duty'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: originalController,
                    decoration: const InputDecoration(
                      labelText:
                          'Absent Teacher Email',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller:
                        substituteController,
                    decoration: const InputDecoration(
                      labelText:
                          'Substitute Teacher Email',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Duty Date'),
                    subtitle: Text(_date(date)),
                    trailing: const Icon(
                      Icons.calendar_today,
                    ),
                    onTap: () async {
                      final selected =
                          await showDatePicker(
                        context: context,
                        firstDate: DateTime.now()
                            .subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                        initialDate: date,
                      );
                      if (selected != null) {
                        setDialogState(
                          () => date = selected,
                        );
                      }
                    },
                  ),
                  TextField(
                    controller: periodController,
                    decoration: const InputDecoration(
                      labelText:
                          'Period / Time',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: classController,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: sectionController,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                    ),
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
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (save == true && mounted) {
      if (originalController.text.trim().isEmpty ||
          substituteController.text.trim().isEmpty ||
          periodController.text.trim().isEmpty ||
          classController.text.trim().isEmpty ||
          subjectController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Teacher emails, period, class and subject are required.',
            ),
          ),
        );
      } else {
        final now = DateTime.now();

        await _repository.assignDuty(
          SubstituteDutyEntity(
            id: 'duty_${now.microsecondsSinceEpoch}',
            originalTeacherEmail:
                originalController.text.trim(),
            substituteTeacherEmail:
                substituteController.text.trim(),
            dutyDate: date,
            periodLabel:
                periodController.text.trim(),
            className: classController.text.trim(),
            sectionName:
                sectionController.text.trim(),
            subjectName:
                subjectController.text.trim(),
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

  static String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year}';
  }
}

class _AdminDutyData {
  const _AdminDutyData({
    required this.leaves,
    required this.duties,
  });

  final List<TeacherLeaveRequestEntity> leaves;
  final List<SubstituteDutyEntity> duties;
}
'@

# Add teacher portal menu import and tile.
$teacherText = ReadText $teacherDashboard

$teacherImport =
  "import 'teacher_leave_duties_page.dart';"

if (-not $teacherText.Contains($teacherImport)) {
  $anchor =
    "import '../../../timetable/presentation/pages/timetable_dashboard_page.dart';"
  if (-not $teacherText.Contains($anchor)) {
    throw 'TEACHER PORTAL IMPORT ANCHOR ERROR.'
  }
  $teacherText = $teacherText.Replace(
    $anchor,
    "$anchor`n$teacherImport"
  )
}

if (-not $teacherText.Contains(
  "const TeacherLeaveDutiesPage()"
)) {
  $anchor = @"
          _tile(
            context,
            Icons.security_outlined,
            'Profile & Security',
"@

  $index = $teacherText.IndexOf(
    $anchor,
    [StringComparison]::Ordinal
  )

  if ($index -lt 0) {
    throw 'TEACHER PORTAL MENU ANCHOR ERROR.'
  }

  $tile = @"
          _tile(
            context,
            Icons.event_busy_outlined,
            'Leave & Duties',
            const TeacherLeaveDutiesPage(),
          ),
"@

  $teacherText =
    $teacherText.Substring(0,$index) +
    $tile +
    $teacherText.Substring($index)
}

WriteText $teacherDashboard $teacherText

# Add admin substitute-duty page to main sidebar.
$sidebarText = ReadText $sidebar
$adminImport =
  "import '../../../teacher_portal/presentation/pages/substitute_duty_management_page.dart';"

if (-not $sidebarText.Contains($adminImport)) {
  $anchor =
    "import '../../../teachers/presentation/pages/teachers_module_page.dart';"
  if (-not $sidebarText.Contains($anchor)) {
    throw 'SIDEBAR IMPORT ANCHOR ERROR.'
  }
  $sidebarText = $sidebarText.Replace(
    $anchor,
    "$anchor`n$adminImport"
  )
}

if (-not $sidebarText.Contains(
  "const SubstituteDutyManagementPage()"
)) {
  $anchor = @"
                    if (_access.hasPermission(AppPermission.staffView))
                      _menuTile(
"@

  $index = $sidebarText.IndexOf(
    $anchor,
    [StringComparison]::Ordinal
  )

  if ($index -lt 0) {
    throw 'SIDEBAR DUTY TILE ANCHOR ERROR.'
  }

  $tile = @"
                    if (_access.hasPermission(AppPermission.staffView))
                      _menuTile(
                        context,
                        icon: Icons.swap_horiz,
                        title: 'Substitute Duties',
                        onTap: () => _open(
                          context,
                          permission: AppPermission.staffView,
                          moduleName: 'Substitute Duties',
                          page: const SubstituteDutyManagementPage(),
                        ),
                      ),
"@

  $sidebarText =
    $sidebarText.Substring(0,$index) +
    $tile +
    $sidebarText.Substring($index)
}

if (-not $sidebarText.Contains("'Substitute Duties' =>")) {
  $anchor =
    "      'Staff' => const Color(0xFFFBBF24),"
  if (-not $sidebarText.Contains($anchor)) {
    throw 'SIDEBAR COLOR ANCHOR ERROR.'
  }
  $sidebarText = $sidebarText.Replace(
    $anchor,
    "$anchor`n      'Substitute Duties' => const Color(0xFF0EA5E9),"
  )
}

WriteText $sidebar $sidebarText

& dart format `
  lib/features/teacher_portal `
  $sidebar

if ($LASTEXITCODE -ne 0) {
  throw "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze `
  lib/features/teacher_portal `
  lib/features/dashboard/presentation/widgets/sidebar.dart `
  --no-fatal-infos `
  --no-fatal-warnings

if ($LASTEXITCODE -ne 0) {
  throw "TEACHER PORTAL PHASE 2 ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Teacher Portal Phase 2 installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Added teacher leave requests, admin approval, substitute assignment, and teacher duty display.' -ForegroundColor Yellow
Write-Host 'Collections: teacher_leave_requests and teacher_substitute_duties.' -ForegroundColor Yellow
