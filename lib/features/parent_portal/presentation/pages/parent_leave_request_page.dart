import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../../notifications/domain/entities/portal_notification_entity.dart';
import '../../../notifications/domain/repositories/portal_notification_repository.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_account_entity.dart';

class ParentLeaveRequestPage extends StatefulWidget {
  const ParentLeaveRequestPage({
    super.key,
    required this.parent,
    required this.student,
  });

  final ParentAccountEntity parent;
  final StudentEntity student;

  @override
  State<ParentLeaveRequestPage> createState() => _ParentLeaveRequestPageState();
}

class _ParentLeaveRequestPageState extends State<ParentLeaveRequestPage> {
  final _service = sl<FirebaseFirestoreService>();
  final _reason = TextEditingController();
  List<Map<String, dynamic>> _items = const [];
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final snapshot = await _service
        .collection(FirestorePaths.parentLeaveRequests)
        .where('parentId', isEqualTo: widget.parent.id)
        .where('studentId', isEqualTo: widget.student.id)
        .get();
    final values =
        snapshot.docs
            .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
            .where(
              (item) =>
                  item['parentId'] == widget.parent.id &&
                  item['studentId'] == widget.student.id,
            )
            .toList()
          ..sort(
            (a, b) => _dateValue(
              b['createdAt'],
            ).compareTo(_dateValue(a['createdAt'])),
          );
    if (!mounted) return;
    setState(() {
      _items = values;
      _loading = false;
    });
  }

  Future<void> _pick(bool from) async {
    final value = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value == null) return;
    setState(() {
      if (from) {
        _from = value;
        if (_to.isBefore(value)) _to = value;
      } else {
        _to = value;
      }
    });
  }

  Future<void> _submit() async {
    if (_reason.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final reference = _service
        .collection(FirestorePaths.parentLeaveRequests)
        .doc();
    await reference.set({
      'parentId': widget.parent.id,
      'parentName': widget.parent.fullName,
      'parentAuthUserId': widget.parent.userId,
      'studentId': widget.student.id,
      'studentName': widget.student.fullName,
      'classId': widget.student.classId,
      'sectionId': widget.student.sectionId,
      'fromDate': Timestamp.fromDate(_from),
      'toDate': Timestamp.fromDate(_to),
      'reason': _reason.text.trim(),
      'attachmentUrl': '',
      'status': 'pending',
      'teacherRemarks': '',
      'adminRemarks': '',
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    await sl<PortalNotificationRepository>().create(
      recipientType: PortalRecipientType.admin,
      recipientId: 'admin',
      title: 'New student leave request',
      message:
          '${widget.parent.fullName} requested leave for ${widget.student.fullName}.',
      type: PortalNotificationType.leave,
      referenceId: reference.id,
      studentId: widget.student.id,
    );
    _reason.clear();
    await _load();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.student.fullName} Leave Requests')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pick(true),
                          icon: const Icon(Icons.event),
                          label: Text('From ${_format(_from)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pick(false),
                          icon: const Icon(Icons.event_available),
                          label: Text('To ${_format(_to)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reason,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: const Icon(Icons.send),
                      label: const Text('Submit Leave Request'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Request History',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No leave request submitted.'),
              ),
            )
          else
            for (final item in _items)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_busy_outlined),
                  title: Text(
                    '${_format(_dateValue(item['fromDate']))} - ${_format(_dateValue(item['toDate']))}',
                  ),
                  subtitle: Text(
                    '${item['reason']}\n${item['adminRemarks'] ?? item['teacherRemarks'] ?? ''}',
                  ),
                  trailing: Chip(
                    label: Text(
                      (item['status']?.toString() ?? 'pending').toUpperCase(),
                    ),
                  ),
                ),
              ),
        ],
      ),
    ),
  );

  static DateTime _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _format(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
