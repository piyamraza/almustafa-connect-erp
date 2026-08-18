import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/admission_test_entities.dart';
import '../../domain/repositories/admission_test_repository.dart';
import '../bloc/admission_test_bloc.dart';
import '../bloc/admission_test_event.dart';
import '../bloc/admission_test_state.dart';
import '../services/admission_test_pdf_service.dart';

const _levels = [
  'Nursery',
  'KG',
  'Class 1',
  'Class 2',
  'Class 3',
  'Class 4',
  'Class 5',
  'Class 6',
  'Class 7',
  'Class 8',
];

class AdmissionTestDashboardPage extends StatelessWidget {
  const AdmissionTestDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<AdmissionTestBloc>()..add(const LoadAdmissionTests()),
    child: const _AdmissionTestView(),
  );
}

class _AdmissionTestView extends StatefulWidget {
  const _AdmissionTestView();
  @override
  State<_AdmissionTestView> createState() => _AdmissionTestViewState();
}

class _AdmissionTestViewState extends State<_AdmissionTestView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admission Tests'),
      actions: const [DashboardNavigationButton()],
    ),
    body: BlocConsumer<AdmissionTestBloc, AdmissionTestState>(
      listener: (context, state) {
        if (state is AdmissionTestLoaded && state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (state is AdmissionTestLoading || state is AdmissionTestInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdmissionTestError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => context.read<AdmissionTestBloc>().add(
                    const LoadAdmissionTests(),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final data = state as AdmissionTestLoaded;
        return Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admission Assessment Workspace',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Build level-wise question banks, generate balanced papers and record admission recommendations.',
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.library_books_outlined),
                        text: 'Question Bank',
                      ),
                      Tab(icon: Icon(Icons.tune), text: 'Paper Templates'),
                      Tab(
                        icon: Icon(Icons.auto_awesome),
                        text: 'Generate Papers',
                      ),
                      Tab(
                        icon: Icon(Icons.how_to_reg_outlined),
                        text: 'Candidates & Results',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _QuestionBankTab(data: data),
                  _TemplatesTab(data: data),
                  _GenerateTab(data: data),
                  _CandidatesTab(data: data),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _QuestionBankTab extends StatefulWidget {
  const _QuestionBankTab({required this.data});
  final AdmissionTestLoaded data;
  @override
  State<_QuestionBankTab> createState() => _QuestionBankTabState();
}

class _QuestionBankTabState extends State<_QuestionBankTab> {
  String _level = 'All';
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final values = widget.data.questions
        .where(
          (q) =>
              (_level == 'All' || q.classLevel == _level) &&
              (q.prompt.toLowerCase().contains(_query) ||
                  q.subject.toLowerCase().contains(_query)),
        )
        .toList();
    return _page(
      Column(
        children: [
          _toolbar(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search questions',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _level,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                  ),
                  items: ['All', ..._levels]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _level = v ?? 'All'),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _questionDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${widget.data.questions.where((q) => q.isDefault).length} default questions • ${widget.data.questions.where((q) => !q.isDefault).length} custom questions',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: values.isEmpty
                ? const Center(
                    child: Text(
                      'No questions found. Add questions before generating a paper.',
                    ),
                  )
                : ListView.separated(
                    itemCount: values.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final q = values[index];
                      return Card(
                        child: ListTile(
                          title: Text(q.prompt),
                          subtitle: Text(
                            '${q.classLevel} • ${q.subject} • ${q.type.label} • ${q.difficulty.label} • ${q.marks} marks',
                          ),
                          trailing: q.isDefault
                              ? const Chip(label: Text('Default'))
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => context
                                      .read<AdmissionTestBloc>()
                                      .add(DeleteAdmissionQuestion(q.id)),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab({required this.data});
  final AdmissionTestLoaded data;
  @override
  Widget build(BuildContext context) => _page(
    ListView.separated(
      itemCount: data.templates.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = data.templates[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(t.classLevel.replaceAll('Class ', '')),
            ),
            title: Text(
              '${t.classLevel} • ${t.mode == AdmissionAssessmentMode.earlyYears ? 'Oral / Observation' : 'Written Paper'}',
            ),
            subtitle: Text(
              '${t.durationMinutes} minutes • Passing ${t.passingPercentage.toStringAsFixed(0)}%\n${t.sections.map((s) => '${s.subject}: ${s.questionCount}').join('  |  ')}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: 'Edit template',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _templateDialog(context, t),
            ),
          ),
        );
      },
    ),
  );
}

class _GenerateTab extends StatefulWidget {
  const _GenerateTab({required this.data});
  final AdmissionTestLoaded data;
  @override
  State<_GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends State<_GenerateTab> {
  String? _templateId;
  final _title = TextEditingController(text: 'Admission Test');
  final _variant = TextEditingController(text: 'A');
  @override
  void dispose() {
    _title.dispose();
    _variant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.data.templates
        .where((t) => t.id == _templateId)
        .firstOrNull;
    return _page(
      ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String>(
                      initialValue: _templateId,
                      decoration: const InputDecoration(
                        labelText: 'Applying class / template',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.data.templates
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.classLevel),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _templateId = v),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Paper title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _variant,
                      decoration: const InputDecoration(
                        labelText: 'Variant',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: selected == null
                        ? null
                        : () => context.read<AdmissionTestBloc>().add(
                            GenerateAdmissionPaper(
                              selected,
                              title: _title.text.trim().isEmpty
                                  ? 'Admission Test'
                                  : _title.text.trim(),
                              variant: _variant.text.trim().isEmpty
                                  ? 'A'
                                  : _variant.text.trim(),
                            ),
                          ),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate & Save'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _customPaperDialog(
                      context,
                      widget.data,
                      seed: widget.data.preview,
                    ),
                    icon: const Icon(Icons.edit_note_outlined),
                    label: const Text('Manual / Hybrid Builder'),
                  ),
                ],
              ),
            ),
          ),
          if (selected != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Required bank: ${selected.sections.map((s) => '${s.subject} (${s.questionCount})').join(', ')} • Difficulty ${selected.easyPercent}/${selected.mediumPercent}/${selected.difficultPercent}',
              ),
            ),
          if (widget.data.preview != null) _paperCard(widget.data.preview!),
          const SizedBox(height: 16),
          Text(
            'Saved Papers',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...widget.data.papers.map(_paperCard),
        ],
      ),
    );
  }

  Widget _paperCard(AdmissionPaperEntity p) => Card(
    child: ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text('${p.title} — ${p.classLevel} (Variant ${p.variant})'),
      subtitle: Text(
        '${p.questions.length} questions • ${p.totalMarks.toStringAsFixed(0)} marks • ${p.durationMinutes} minutes',
      ),
      trailing: IconButton(
        tooltip: 'Print paper and answer key',
        icon: const Icon(Icons.print_outlined),
        onPressed: () => const AdmissionTestPdfService().printPaper(p),
      ),
    ),
  );
}

class _CandidatesTab extends StatelessWidget {
  const _CandidatesTab({required this.data});
  final AdmissionTestLoaded data;
  @override
  Widget build(BuildContext context) => _page(
    Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _candidateDialog(context, data),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Add Candidate / Result'),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: data.candidates.isEmpty
              ? const Center(
                  child: Text('No admission candidates recorded yet.'),
                )
              : ListView.separated(
                  itemCount: data.candidates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final c = data.candidates[index];
                    return Card(
                      child: ListTile(
                        onTap: () =>
                            _candidateDialog(context, data, existing: c),
                        leading: CircleAvatar(
                          child: Text(
                            c.studentName.isEmpty
                                ? '?'
                                : c.studentName[0].toUpperCase(),
                          ),
                        ),
                        title: Text('${c.studentName} • ${c.applicantNumber}'),
                        subtitle: Text(
                          '${c.applyingClass} • ${DateFormat('dd MMM yyyy').format(c.testDate)} • ${c.percentage.toStringAsFixed(1)}%',
                        ),
                        trailing: Chip(label: Text(c.recommendation.label)),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

Widget _page(Widget child) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1400),
      child: child,
    ),
  ),
);
Widget _toolbar({required List<Widget> children}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(spacing: 10, children: children),
);

Future<void> _questionDialog(BuildContext context) async {
  final repository = sl<AdmissionTestRepository>();
  final prompt = TextEditingController(),
      subject = TextEditingController(text: 'English'),
      answer = TextEditingController(),
      options = TextEditingController(),
      marks = TextEditingController(text: '1');
  var level = _levels.first,
      type = AdmissionQuestionType.multipleChoice,
      difficulty = AdmissionQuestionDifficulty.easy;
  final value = await showDialog<AdmissionQuestionEntity>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add Admission Question'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: level,
                  decoration: const InputDecoration(labelText: 'Class level'),
                  items: _levels
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => level = v!),
                ),
                TextField(
                  controller: subject,
                  decoration: const InputDecoration(
                    labelText: 'Subject / assessment area',
                  ),
                ),
                DropdownButtonFormField<AdmissionQuestionType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Question type'),
                  items: AdmissionQuestionType.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => type = v!),
                ),
                DropdownButtonFormField<AdmissionQuestionDifficulty>(
                  initialValue: difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: AdmissionQuestionDifficulty.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => difficulty = v!),
                ),
                TextField(
                  controller: prompt,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Question / observation prompt',
                  ),
                ),
                if (type == AdmissionQuestionType.multipleChoice)
                  TextField(
                    controller: options,
                    decoration: const InputDecoration(
                      labelText: 'Options (comma separated)',
                    ),
                  ),
                TextField(
                  controller: answer,
                  decoration: const InputDecoration(
                    labelText: 'Correct answer / expected response',
                  ),
                ),
                TextField(
                  controller: marks,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Marks'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: prompt.text.trim().isEmpty || subject.text.trim().isEmpty
                ? null
                : () => Navigator.pop(
                    dialog,
                    AdmissionQuestionEntity(
                      id: repository.newId(
                        FirestorePaths.admissionTestQuestions,
                      ),
                      classLevel: level,
                      subject: subject.text.trim(),
                      type: type,
                      difficulty: difficulty,
                      prompt: prompt.text.trim(),
                      marks: double.tryParse(marks.text) ?? 1,
                      correctAnswer: answer.text.trim(),
                      options: options.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                      createdAt: DateTime.now(),
                    ),
                  ),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  for (final c in [prompt, subject, answer, options, marks]) {
    c.dispose();
  }
  if (value != null && context.mounted) {
    context.read<AdmissionTestBloc>().add(SaveAdmissionQuestion(value));
  }
}

Future<void> _templateDialog(
  BuildContext context,
  AdmissionPaperTemplateEntity existing,
) async {
  final duration = TextEditingController(text: '${existing.durationMinutes}'),
      passing = TextEditingController(
        text: existing.passingPercentage.toStringAsFixed(0),
      );
  var sections = existing.sections.toList();
  final value = await showDialog<AdmissionPaperTemplateEntity>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('${existing.classLevel} Template'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: duration,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration minutes',
                  ),
                ),
                TextField(
                  controller: passing,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Passing percentage',
                  ),
                ),
                const SizedBox(height: 12),
                ...sections.asMap().entries.map(
                  (entry) => Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: entry.value.subject,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                          ),
                          onChanged: (v) =>
                              sections[entry.key] = AdmissionTemplateSection(
                                subject: v,
                                questionCount: entry.value.questionCount,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 130,
                        child: TextFormField(
                          initialValue: '${entry.value.questionCount}',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Questions',
                          ),
                          onChanged: (v) =>
                              sections[entry.key] = AdmissionTemplateSection(
                                subject: entry.value.subject,
                                questionCount: int.tryParse(v) ?? 0,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => sections.removeAt(entry.key)),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(
                    () => sections = [
                      ...sections,
                      const AdmissionTemplateSection(
                        subject: 'New Subject',
                        questionCount: 5,
                      ),
                    ],
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Section'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialog,
              AdmissionPaperTemplateEntity(
                id: existing.id,
                classLevel: existing.classLevel,
                mode: existing.mode,
                durationMinutes:
                    int.tryParse(duration.text) ?? existing.durationMinutes,
                passingPercentage:
                    double.tryParse(passing.text) ?? existing.passingPercentage,
                sections: sections
                    .where(
                      (s) => s.subject.trim().isNotEmpty && s.questionCount > 0,
                    )
                    .toList(),
                updatedAt: DateTime.now(),
                easyPercent: existing.easyPercent,
                mediumPercent: existing.mediumPercent,
                difficultPercent: existing.difficultPercent,
              ),
            ),
            child: const Text('Save Template'),
          ),
        ],
      ),
    ),
  );
  duration.dispose();
  passing.dispose();
  if (value != null && context.mounted) {
    context.read<AdmissionTestBloc>().add(SaveAdmissionTemplate(value));
  }
}

Future<void> _customPaperDialog(
  BuildContext context,
  AdmissionTestLoaded data, {
  AdmissionPaperEntity? seed,
}) async {
  final repository = sl<AdmissionTestRepository>();
  final title = TextEditingController(text: seed?.title ?? 'Admission Test');
  final variant = TextEditingController(text: seed?.variant ?? 'A');
  final duration = TextEditingController(
    text: '${seed?.durationMinutes ?? 60}',
  );
  final passing = TextEditingController(
    text: seed?.passingPercentage.toStringAsFixed(0) ?? '50',
  );
  var level = seed?.classLevel ?? _levels.first;
  var selectedIds = seed?.questions.map((q) => q.id).toSet() ?? <String>{};
  final value = await showDialog<AdmissionPaperEntity>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (context, setState) {
        final questions = data.questions
            .where((q) => q.classLevel == level)
            .toList();
        final selected = questions
            .where((q) => selectedIds.contains(q.id))
            .toList();
        final template = data.templates
            .where((t) => t.classLevel == level)
            .firstOrNull;
        return AlertDialog(
          title: const Text('Manual / Hybrid Paper Builder'),
          content: SizedBox(
            width: 760,
            height: 620,
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: level,
                        decoration: const InputDecoration(labelText: 'Class'),
                        items: _levels
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          level = value!;
                          selectedIds = {};
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: title,
                        decoration: const InputDecoration(
                          labelText: 'Paper title',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: variant,
                        decoration: const InputDecoration(labelText: 'Variant'),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: duration,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Minutes'),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: passing,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Passing %',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${selected.length} selected • ${selected.fold<double>(0, (sum, q) => sum + q.marks).toStringAsFixed(0)} marks',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: questions.isEmpty
                      ? const Center(
                          child: Text('No questions available for this class.'),
                        )
                      : ListView.builder(
                          itemCount: questions.length,
                          itemBuilder: (context, index) {
                            final q = questions[index];
                            return CheckboxListTile(
                              value: selectedIds.contains(q.id),
                              title: Text(q.prompt),
                              subtitle: Text(
                                '${q.subject} • ${q.type.label} • ${q.difficulty.label} • ${q.marks} marks',
                              ),
                              onChanged: (checked) => setState(() {
                                checked == true
                                    ? selectedIds.add(q.id)
                                    : selectedIds.remove(q.id);
                              }),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(
                      dialog,
                      AdmissionPaperEntity(
                        id: repository.newId(
                          FirestorePaths.admissionTestPapers,
                        ),
                        title: title.text.trim().isEmpty
                            ? 'Admission Test'
                            : title.text.trim(),
                        classLevel: level,
                        mode: template?.mode ?? AdmissionAssessmentMode.written,
                        durationMinutes:
                            int.tryParse(duration.text) ??
                            template?.durationMinutes ??
                            60,
                        passingPercentage: double.tryParse(passing.text) ?? 50,
                        questions: selected,
                        createdAt: DateTime.now(),
                        variant: variant.text.trim().isEmpty
                            ? 'A'
                            : variant.text.trim(),
                      ),
                    ),
              child: const Text('Save Paper'),
            ),
          ],
        );
      },
    ),
  );
  title.dispose();
  variant.dispose();
  duration.dispose();
  passing.dispose();
  if (value != null && context.mounted) {
    context.read<AdmissionTestBloc>().add(SaveCustomAdmissionPaper(value));
  }
}

Future<void> _candidateDialog(
  BuildContext context,
  AdmissionTestLoaded data, {
  AdmissionCandidateEntity? existing,
}) async {
  final repository = sl<AdmissionTestRepository>();
  final number = TextEditingController(
        text:
            existing?.applicantNumber ??
            'APP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      ),
      name = TextEditingController(text: existing?.studentName),
      guardian = TextEditingController(text: existing?.guardianName),
      phone = TextEditingController(text: existing?.guardianPhone),
      obtained = TextEditingController(
        text: existing == null ? '' : existing.obtainedMarks.toString(),
      ),
      remarks = TextEditingController(text: existing?.remarks);
  var level = existing?.applyingClass ?? _levels.first;
  String? paperId = existing?.paperId.isEmpty == false
      ? existing!.paperId
      : null;
  var recommendation =
      existing?.recommendation ?? AdmissionRecommendation.pending;
  var date = existing?.testDate ?? DateTime.now();
  var observations = Map<String, String>.from(
    existing?.observations ?? const {},
  );
  final value = await showDialog<AdmissionCandidateEntity>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (context, setState) {
        final papers = data.papers.where((p) => p.classLevel == level).toList();
        final paper = papers.where((p) => p.id == paperId).firstOrNull;
        return AlertDialog(
          title: Text(
            existing == null
                ? 'Add Admission Candidate'
                : 'Update Candidate Result',
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: number,
                    decoration: const InputDecoration(
                      labelText: 'Applicant number',
                    ),
                  ),
                  TextField(
                    controller: name,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Student name',
                    ),
                  ),
                  TextField(
                    controller: guardian,
                    decoration: const InputDecoration(
                      labelText: 'Guardian name',
                    ),
                  ),
                  TextField(
                    controller: phone,
                    decoration: const InputDecoration(
                      labelText: 'Guardian phone',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: level,
                    decoration: const InputDecoration(
                      labelText: 'Applying class',
                    ),
                    items: _levels
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      level = v!;
                      paperId = null;
                      observations = {};
                    }),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: paper?.id,
                    decoration: const InputDecoration(
                      labelText: 'Assigned paper',
                    ),
                    items: papers
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.title} — ${p.variant}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      paperId = v;
                      observations = {};
                    }),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Test date'),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(date)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: date,
                      );
                      if (picked != null) setState(() => date = picked);
                    },
                  ),
                  TextField(
                    controller: obtained,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Obtained marks',
                      helperText:
                          'Paper total: ${paper?.totalMarks.toStringAsFixed(0) ?? '0'}',
                    ),
                  ),
                  if (paper?.mode == AdmissionAssessmentMode.earlyYears) ...[
                    const Divider(height: 28),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Oral & Observation Checklist',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final question in paper!.questions)
                      DropdownButtonFormField<String>(
                        initialValue: observations[question.id],
                        decoration: InputDecoration(labelText: question.prompt),
                        items: const [
                          DropdownMenuItem(value: 'Good', child: Text('Good')),
                          DropdownMenuItem(
                            value: 'Satisfactory',
                            child: Text('Satisfactory'),
                          ),
                          DropdownMenuItem(
                            value: 'Needs Support',
                            child: Text('Needs Support'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          if (value != null) observations[question.id] = value;
                        }),
                      ),
                  ],
                  DropdownButtonFormField<AdmissionRecommendation>(
                    initialValue: recommendation,
                    decoration: const InputDecoration(
                      labelText: 'Recommendation',
                    ),
                    items: AdmissionRecommendation.values
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text(e.label)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => recommendation = v!),
                  ),
                  TextField(
                    controller: remarks,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Remarks'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: paper == null || name.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(
                      dialog,
                      AdmissionCandidateEntity(
                        id:
                            existing?.id ??
                            repository.newId(
                              FirestorePaths.admissionTestCandidates,
                            ),
                        applicantNumber: number.text.trim(),
                        studentName: name.text.trim(),
                        guardianName: guardian.text.trim(),
                        guardianPhone: phone.text.trim(),
                        applyingClass: level,
                        testDate: date,
                        paperId: paper.id,
                        paperTitle: paper.title,
                        obtainedMarks: double.tryParse(obtained.text) ?? 0,
                        totalMarks: paper.totalMarks,
                        observations: observations,
                        recommendation: recommendation,
                        remarks: remarks.text.trim(),
                        updatedAt: DateTime.now(),
                      ),
                    ),
              child: const Text('Save Result'),
            ),
          ],
        );
      },
    ),
  );
  for (final c in [number, name, guardian, phone, obtained, remarks]) {
    c.dispose();
  }
  if (value != null && context.mounted) {
    context.read<AdmissionTestBloc>().add(SaveAdmissionCandidate(value));
  }
}
