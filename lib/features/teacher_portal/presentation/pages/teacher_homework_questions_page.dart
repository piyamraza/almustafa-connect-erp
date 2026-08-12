import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../homework/domain/entities/homework_question_entity.dart';
import '../../../homework/domain/repositories/homework_question_repository.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';

class TeacherHomeworkQuestionsPage extends StatefulWidget {
  const TeacherHomeworkQuestionsPage({super.key, required this.teacher});
  const TeacherHomeworkQuestionsPage.admin({super.key}) : teacher = null;

  final TeacherEntity? teacher;
  bool get isAdmin => teacher == null;

  @override
  State<TeacherHomeworkQuestionsPage> createState() =>
      _TeacherHomeworkQuestionsPageState();
}

class _TeacherHomeworkQuestionsPageState
    extends State<TeacherHomeworkQuestionsPage> {
  final _repository = sl<HomeworkQuestionRepository>();
  List<HomeworkQuestionEntity> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = widget.isAdmin
        ? await _repository.getForAdmin()
        : await _repository.getForTeacher(widget.teacher!.id);
    if (!mounted) return;
    setState(() {
      _items = values;
      _loading = false;
    });
  }

  Future<void> _reply(HomeworkQuestionEntity question) async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reply to ${question.parentName}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Reply',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || message.trim().isEmpty) return;
    await _repository.addReply(
      question: question,
      reply: HomeworkQuestionReplyEntity(
        id: _repository.generateReplyId(),
        authorId: widget.isAdmin ? 'admin' : widget.teacher!.id,
        authorName: widget.isAdmin ? 'School Administration' : widget.teacher!.fullName,
        authorType: widget.isAdmin
            ? HomeworkReplyAuthorType.admin
            : HomeworkReplyAuthorType.teacher,
        message: message.trim(),
        createdAt: DateTime.now(),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _items
        .where((item) => item.status == HomeworkQuestionStatus.newQuestion)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.isAdmin ? 'Parent Queries' : 'Parent Questions'} ($pending pending)',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.question_answer_outlined, size: 52),
                  SizedBox(height: 12),
                  Text(
                    'No homework questions yet.',
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        child: Text(
                          item.studentName.isEmpty
                              ? '?'
                              : item.studentName[0].toUpperCase(),
                        ),
                      ),
                      title: Text(
                        item.question,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${item.studentName} • ${item.subjectName} • ${item.homeworkTitle}',
                      ),
                      trailing: Chip(label: Text(_status(item.status))),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      children: [
                        for (final reply in item.replies)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.reply),
                            title: Text(reply.authorName),
                            subtitle: Text(reply.message),
                          ),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed:
                                  item.status == HomeworkQuestionStatus.closed
                                  ? null
                                  : () => _reply(item),
                              icon: const Icon(Icons.reply),
                              label: const Text('Reply'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed:
                                  item.status == HomeworkQuestionStatus.closed
                                  ? null
                                  : () async {
                                      await _repository.closeQuestion(item);
                                      await _load();
                                    },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Close'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  static String _status(HomeworkQuestionStatus value) => switch (value) {
    HomeworkQuestionStatus.newQuestion => 'New',
    HomeworkQuestionStatus.replied => 'Replied',
    HomeworkQuestionStatus.closed => 'Closed',
  };
}
