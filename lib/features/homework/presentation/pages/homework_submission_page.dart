import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/homework_entity.dart';
import '../../domain/entities/homework_submission_entity.dart';
import '../../domain/repositories/homework_submission_repository.dart';
import '../../domain/services/homework_attachment_service.dart';

class HomeworkSubmissionPage extends StatefulWidget {
  const HomeworkSubmissionPage({
    super.key,
    required this.homework,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.classId,
    required this.sectionId,
    this.existing,
  });

  final HomeworkEntity homework;
  final String studentId;
  final String studentName;
  final String admissionNo;
  final String classId;
  final String sectionId;
  final HomeworkSubmissionEntity? existing;

  @override
  State<HomeworkSubmissionPage> createState() => _HomeworkSubmissionPageState();
}

class _HomeworkSubmissionPageState extends State<HomeworkSubmissionPage> {
  late final TextEditingController _text;
  final List<HomeworkAttachmentEntity> _attachments = [];
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.existing?.submissionText ?? '');
    _attachments.addAll(widget.existing?.attachments ?? const []);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    setState(() => _uploading = true);
    try {
      final id =
          widget.existing?.id ??
          sl<HomeworkSubmissionRepository>().generateId();
      final values = await sl<HomeworkAttachmentService>().pickAndUpload(
        homeworkId: 'submission_$id',
      );
      if (mounted) setState(() => _attachments.addAll(values));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final isLate = now.isAfter(widget.homework.dueDate);
    final old = widget.existing;

    final submission = HomeworkSubmissionEntity(
      id: old?.id ?? sl<HomeworkSubmissionRepository>().generateId(),
      homeworkId: widget.homework.id,
      studentId: widget.studentId,
      studentName: widget.studentName,
      admissionNo: widget.admissionNo,
      classId: widget.classId,
      sectionId: widget.sectionId,
      submissionText: _text.text.trim(),
      attachments: _attachments,
      status: isLate
          ? HomeworkSubmissionStatus.late
          : HomeworkSubmissionStatus.submitted,
      submittedAt: now,
      isLate: isLate,
      teacherRemarks: old?.teacherRemarks ?? '',
      marksAwarded: old?.marksAwarded,
      maxMarks: old?.maxMarks,
      reviewedBy: old?.reviewedBy,
      reviewedAt: old?.reviewedAt,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );

    if (mounted) Navigator.pop(context, submission);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Submit Homework')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              title: Text(widget.homework.title),
              subtitle: Text(
                '${widget.homework.subjectName} • '
                'Due ${_date(widget.homework.dueDate)}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Submission text / comments',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Submission Attachments')),
                      FilledButton.tonalIcon(
                        onPressed: _uploading ? null : _upload,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload'),
                      ),
                    ],
                  ),
                  for (final item in _attachments)
                    ListTile(
                      leading: const Icon(Icons.attach_file),
                      title: Text(item.fileName),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.send),
              label: const Text('Submit Homework'),
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
