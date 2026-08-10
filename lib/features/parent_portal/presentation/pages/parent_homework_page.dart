import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../homework/domain/entities/homework_entity.dart';
import '../../../homework/domain/entities/syllabus_entry_entity.dart';
import '../../../homework/domain/entities/syllabus_plan_entity.dart';
import '../../../homework/domain/repositories/syllabus_repository.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_homework_summary.dart';
import '../../domain/services/parent_homework_service.dart';

class ParentHomeworkPage extends StatefulWidget {
  const ParentHomeworkPage({super.key, required this.student});

  final StudentEntity student;

  @override
  State<ParentHomeworkPage> createState() => _ParentHomeworkPageState();
}

class _ParentHomeworkPageState extends State<ParentHomeworkPage> {
  final ParentHomeworkService _service = sl<ParentHomeworkService>();

  ParentHomeworkSummary? _summary;
  List<SyllabusPlanEntity> _syllabusPlans = const [];
  Map<String, List<SyllabusEntryEntity>> _syllabusEntries = const {};
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<Object>([
        _service.loadHomework(
          academicSession: '2026-2027',
          classId: widget.student.classId,
          sectionId: widget.student.sectionId,
        ),
        sl<SyllabusRepository>().getPlans(
          academicSession: '2026-2027',
          publishedOnly: true,
        ),
      ]);
      final plans = results[1] as List<SyllabusPlanEntity>;
      final entryLists = await Future.wait(
        plans.map(
          (plan) => sl<SyllabusRepository>().getEntriesForPlan(plan.id),
        ),
      );

      if (!mounted) return;

      setState(() {
        _summary = results[0] as ParentHomeworkSummary;
        _syllabusPlans = plans;
        _syllabusEntries = {
          for (var index = 0; index < plans.length; index++)
            plans[index].id: entryLists[index]
                .where(
                  (entry) =>
                      entry.classId == widget.student.classId &&
                      entry.sectionId == widget.student.sectionId,
                )
                .toList(),
        };
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = error
            .toString()
            .replaceFirst('StateError: ', '')
            .replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.student.fullName} Homework')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.error_outline, size: 54),
          const SizedBox(height: 14),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ),
        ],
      );
    }

    final summary = _summary!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _HomeworkSummaryGrid(summary: summary),
        const SizedBox(height: 18),
        Text(
          'Published Syllabus',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_syllabusPlans.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(22),
              child: Text(
                'No published syllabus is available.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (final plan in _syllabusPlans)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.school_outlined),
                  ),
                  title: Text(
                    plan.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(plan.academicSession),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    if ((_syllabusEntries[plan.id] ?? const []).isEmpty)
                      const ListTile(
                        title: Text(
                          'No syllabus has been added for this class.',
                        ),
                      )
                    else
                      for (final entry in _syllabusEntries[plan.id] ?? const [])
                        ListTile(
                          leading: const Icon(Icons.menu_book_outlined),
                          title: Text(
                            entry.subjectName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(entry.content),
                        ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 18),
        Text(
          'Published Homework',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (summary.items.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'No published homework is available.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...summary.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HomeworkCard(homework: item),
            ),
          ),
      ],
    );
  }
}

class _HomeworkSummaryGrid extends StatelessWidget {
  const _HomeworkSummaryGrid({required this.summary});

  final ParentHomeworkSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total', summary.total, Icons.menu_book_outlined),
      ('Due Today', summary.dueToday, Icons.today_outlined),
      ('Upcoming', summary.upcoming, Icons.upcoming_outlined),
      ('Overdue', summary.overdue, Icons.warning_amber_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 800
            ? 4
            : constraints.maxWidth >= 480
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 1 ? 3.4 : 2.0,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(item.$3),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.$2}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(item.$1),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({required this.homework});

  final HomeworkEntity homework;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dueToday =
        homework.dueDate.year == now.year &&
        homework.dueDate.month == now.month &&
        homework.dueDate.day == now.day;

    final statusLabel = homework.isOverdue
        ? 'OVERDUE'
        : dueToday
        ? 'DUE TODAY'
        : 'UPCOMING';

    return Card(
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.menu_book_outlined)),
        title: Text(
          homework.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${homework.subjectName} | '
          '${homework.teacherName} | '
          'Due ${_date(homework.dueDate)}',
        ),
        trailing: Chip(label: Text(statusLabel)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (homework.description.trim().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(homework.description),
            ),
          if (homework.instructions.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Instructions',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(homework.instructions),
            ),
          ],
          if (homework.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Attachments',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),
            for (final attachment in homework.attachments)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file),
                title: Text(attachment.fileName),
                subtitle: Text(attachment.fileType),
                trailing: const Icon(Icons.open_in_new),
                onTap: () async {
                  final uri = Uri.tryParse(attachment.fileUrl);

                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
          ],
        ],
      ),
    );
  }

  static String _date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
