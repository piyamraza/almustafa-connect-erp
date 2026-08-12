import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../domain/entities/homework_submission_entity.dart';

class HomeworkReviewPage extends StatefulWidget {
  const HomeworkReviewPage({super.key, required this.submission});

  final HomeworkSubmissionEntity submission;

  @override
  State<HomeworkReviewPage> createState() => _HomeworkReviewPageState();
}

class _HomeworkReviewPageState extends State<HomeworkReviewPage> {
  late final TextEditingController _remarks;
  late final TextEditingController _marks;
  late final TextEditingController _maxMarks;
  HomeworkSubmissionStatus _status = HomeworkSubmissionStatus.reviewed;

  @override
  void initState() {
    super.initState();
    _remarks = TextEditingController(text: widget.submission.teacherRemarks);
    _marks = TextEditingController(
      text: widget.submission.marksAwarded?.toString() ?? '',
    );
    _maxMarks = TextEditingController(
      text: widget.submission.maxMarks?.toString() ?? '',
    );
    _status = widget.submission.status == HomeworkSubmissionStatus.returned
        ? HomeworkSubmissionStatus.returned
        : HomeworkSubmissionStatus.reviewed;
  }

  @override
  void dispose() {
    _remarks.dispose();
    _marks.dispose();
    _maxMarks.dispose();
    super.dispose();
  }

  void _save() {
    final now = DateTime.now();
    Navigator.pop(
      context,
      widget.submission.copyWith(
        status: _status,
        teacherRemarks: _remarks.text.trim(),
        marksAwarded: double.tryParse(_marks.text.trim()),
        maxMarks: double.tryParse(_maxMarks.text.trim()),
        reviewedBy: 'Admin',
        reviewedAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: const Text('Review Submission'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              title: Text(widget.submission.studentName),
              subtitle: Text(widget.submission.admissionNo),
            ),
          ),
          const SizedBox(height: 12),
          Text(widget.submission.submissionText),
          const SizedBox(height: 12),
          for (final attachment in widget.submission.attachments)
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(attachment.fileName),
              subtitle: Text(attachment.fileUrl),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarks,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Teacher Remarks',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _marks,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Marks Awarded',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxMarks,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maximum Marks',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<HomeworkSubmissionStatus>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'Review Action',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: HomeworkSubmissionStatus.reviewed,
                child: Text('Reviewed / Accepted'),
              ),
              DropdownMenuItem(
                value: HomeworkSubmissionStatus.returned,
                child: Text('Return for Correction'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _status = value);
            },
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Save Review'),
            ),
          ),
        ],
      ),
    );
  }
}
