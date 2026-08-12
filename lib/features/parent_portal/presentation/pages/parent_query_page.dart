import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../homework/domain/entities/homework_question_entity.dart';
import '../../../homework/domain/repositories/homework_question_repository.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_account_entity.dart';

class ParentQueryPage extends StatefulWidget {
  const ParentQueryPage({
    super.key,
    required this.parent,
    required this.student,
  });

  final ParentAccountEntity parent;
  final StudentEntity student;

  @override
  State<ParentQueryPage> createState() => _ParentQueryPageState();
}

class _ParentQueryPageState extends State<ParentQueryPage> {
  final _repository = sl<HomeworkQuestionRepository>();
  final _controller = TextEditingController();
  List<HomeworkQuestionEntity> _items = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final values = await _repository.getForParent(widget.parent.id);
    if (!mounted) return;
    setState(() {
      _items = values.where((item) => item.homeworkId.isEmpty).toList();
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    await _repository.askQuestion(
      HomeworkQuestionEntity(
        id: _repository.generateId(),
        homeworkId: '',
        homeworkTitle: 'General Parent Query',
        parentId: widget.parent.id,
        parentName: widget.parent.fullName,
        studentId: widget.student.id,
        studentName: widget.student.fullName,
        teacherId: '',
        classId: widget.student.classId,
        sectionId: widget.student.sectionId,
        subjectId: '',
        subjectName: 'Administration',
        question: text,
        status: HomeworkQuestionStatus.newQuestion,
        createdAt: now,
        updatedAt: now,
        replies: const [],
      ),
    );
    _controller.clear();
    await _load();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ask Administration')),
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
                  TextField(
                    controller: _controller,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Your query',
                      hintText: 'Write your question for school administration',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Submit Query'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Previous Queries',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            const Card(child: ListTile(title: Text('No query submitted yet.')))
          else
            for (final item in _items)
              Card(
                child: ExpansionTile(
                  title: Text(item.question),
                  subtitle: Text(item.status.name),
                  children: [
                    for (final reply in item.replies)
                      ListTile(
                        leading: const Icon(Icons.reply_outlined),
                        title: Text(reply.authorName),
                        subtitle: Text(reply.message),
                      ),
                  ],
                ),
              ),
        ],
      ),
    ),
  );
}
