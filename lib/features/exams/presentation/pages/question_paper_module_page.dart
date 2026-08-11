import 'dart:typed_data';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/subject_component_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/repositories/subject_component_repository.dart';
import '../../../settings/domain/usecases/manage_settings.dart';
import '../../data/repositories/question_paper_repository.dart';
import '../../domain/entities/exam_question_entity.dart';
import '../services/question_paper_pdf_service.dart';

const _blue = Color(0xFF2457C5);

class QuestionPaperModulePage extends StatefulWidget {
  const QuestionPaperModulePage({super.key});
  @override
  State<QuestionPaperModulePage> createState() =>
      _QuestionPaperModulePageState();
}

class _QuestionPaperModulePageState extends State<QuestionPaperModulePage> {
  final _repository = sl<QuestionPaperRepository>();
  final _structure = sl<AcademicStructureRepository>();
  final _componentRepository = sl<SubjectComponentRepository>();
  final _search = TextEditingController();
  List<AcademicClassEntity> _classes = const [];
  List<AcademicSubjectEntity> _subjects = const [];
  List<SubjectComponentEntity> _components = const [];
  Map<String, SubjectPaperProgress> _progress = const {};
  bool _loading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final values = await Future.wait([
        _structure.getClasses(),
        _structure.getSubjects(),
        _componentRepository.getComponents(),
        _repository.getAllProgress(),
      ]);
      if (!mounted) return;
      setState(() {
        _classes = (values[0] as List<AcademicClassEntity>)
            .where((e) => e.isActive)
            .toList();
        _subjects = (values[1] as List<AcademicSubjectEntity>)
            .where((e) => e.isActive)
            .toList();
        _components = (values[2] as List<SubjectComponentEntity>)
            .where((component) => component.isActive)
            .toList();
        _progress = values[3] as Map<String, SubjectPaperProgress>;
      });
    } catch (error) {
      _message(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text.replaceFirst('StateError: ', ''))),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    appBar: AppBar(
      titleSpacing: 20,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question Papers',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            'Class & subject workspace',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      actions: [
        const DashboardNavigationButton(),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _toolbar(),
              Expanded(child: _classTable()),
            ],
          ),
  );

  Widget _toolbar() {
    final filters = ['All', 'Pending', 'In Progress', 'Complete'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = SizedBox(
            height: 40,
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 19),
                hintText: 'Search class or subject',
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          );
          final chips = filters
              .map(
                (label) => FilterChip(
                  label: Text(label),
                  selected: _filter == label,
                  onSelected: (_) => setState(() => _filter = label),
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList();
          if (constraints.maxWidth < 700) {
            return Column(
              children: [
                search,
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final chip in chips)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: chip,
                        ),
                    ],
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              ...chips.map(
                (chip) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: chip,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _classTable() {
    final query = _search.text.trim().toLowerCase();
    final rows = _classes.where((classItem) {
      final subjects = _forClass(classItem.id);
      return query.isEmpty ||
          _classDisplayName(classItem.name).toLowerCase().contains(query) ||
          subjects.any((e) => e.displayName.toLowerCase().contains(query));
    }).toList();
    if (rows.isEmpty) {
      return const Center(child: Text('No classes or subjects found.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final classItem = rows[index];
        var subjects = _forClass(classItem.id);
        subjects = subjects
            .where((subject) => _matchesFilter(_status(classItem.id, subject)))
            .toList();
        if (subjects.isEmpty && _filter != 'All') {
          return const SizedBox.shrink();
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3E8F2)),
          ),
          child: Flex(
            direction: MediaQuery.sizeOf(context).width < 700
                ? Axis.vertical
                : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: MediaQuery.sizeOf(context).width < 700
                    ? double.infinity
                    : 132,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.all(Radius.circular(11)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _classDisplayName(classItem.name),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B3470),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${subjects.length} papers',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                fit: MediaQuery.sizeOf(context).width < 700
                    ? FlexFit.loose
                    : FlexFit.tight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: subjects
                        .map((subject) => _subjectCard(classItem, subject))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_PaperSubjectOption> _forClass(String classId) {
    final seen = <String>{};
    final subjects = _subjects
        .where((subject) => subject.classId == classId && seen.add(subject.id))
        .toList();
    final result = <_PaperSubjectOption>[];
    for (final subject in subjects) {
      final components =
          _components
              .where((component) => component.parentSubjectId == subject.id)
              .toList()
            ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      if (subject.useComponentsInExamination && components.isNotEmpty) {
        result.addAll(
          components.map(
            (component) =>
                _PaperSubjectOption(subject: subject, component: component),
          ),
        );
      } else {
        result.add(_PaperSubjectOption(subject: subject));
      }
    }
    return result..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  SubjectPaperProgress _status(String classId, _PaperSubjectOption option) =>
      _progress[option.progressKey(classId)] ??
      SubjectPaperProgress(
        classId: classId,
        subjectId: option.subject.id,
        componentId: option.component?.id ?? '',
      );
  bool _matchesFilter(SubjectPaperProgress p) => switch (_filter) {
    'Pending' =>
      p.objectiveStatus == PaperSectionStatus.pending &&
          p.subjectiveStatus == PaperSectionStatus.pending,
    'In Progress' =>
      !p.isComplete &&
          (p.objectiveStatus != PaperSectionStatus.pending ||
              p.subjectiveStatus != PaperSectionStatus.pending),
    'Complete' => p.isComplete,
    _ => true,
  };

  Widget _subjectCard(
    AcademicClassEntity classItem,
    _PaperSubjectOption option,
  ) {
    final value = _status(classItem.id, option);
    final accent = value.isComplete
        ? const Color(0xFF14804A)
        : (value.objectiveStatus != PaperSectionStatus.pending ||
                  value.subjectiveStatus != PaperSectionStatus.pending
              ? const Color(0xFFB76E00)
              : const Color(0xFF718096));
    return Material(
      color: Color.alphaBlend(accent.withValues(alpha: .055), Colors.white),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SubjectPaperWorkspacePage(
                classItem: classItem,
                subject: option.subject,
                component: option.component,
              ),
            ),
          );
          await _load();
        },
        child: Container(
          width: MediaQuery.sizeOf(context).width < 700 ? double.infinity : 205,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: accent.withValues(alpha: .35)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      option.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 17, color: accent),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(child: _miniStatus('OBJ', value.objectiveStatus)),
                  const SizedBox(width: 5),
                  Expanded(child: _miniStatus('SUB', value.subjectiveStatus)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStatus(String label, PaperSectionStatus status) {
    final color = status == PaperSectionStatus.complete
        ? const Color(0xFF14804A)
        : status == PaperSectionStatus.draft
        ? const Color(0xFFB76E00)
        : const Color(0xFF8491A5);
    final icon = status == PaperSectionStatus.complete
        ? Icons.check_circle
        : status == PaperSectionStatus.draft
        ? Icons.timelapse
        : Icons.radio_button_unchecked;
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          '$label ${status.label}',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PaperSubjectOption {
  const _PaperSubjectOption({required this.subject, this.component});
  final AcademicSubjectEntity subject;
  final SubjectComponentEntity? component;
  String get displayName => component == null
      ? subject.name
      : _componentDisplayName(subject.name, component!.componentName);
  String progressKey(String classId) => component == null
      ? '${classId}_${subject.id}'
      : '${classId}_${subject.id}_${component!.id}';
}

class SubjectPaperWorkspacePage extends StatefulWidget {
  const SubjectPaperWorkspacePage({
    super.key,
    required this.classItem,
    required this.subject,
    this.component,
  });
  final AcademicClassEntity classItem;
  final AcademicSubjectEntity subject;
  final SubjectComponentEntity? component;
  @override
  State<SubjectPaperWorkspacePage> createState() =>
      _SubjectPaperWorkspacePageState();
}

class _SubjectPaperWorkspacePageState extends State<SubjectPaperWorkspacePage> {
  final _repository = sl<QuestionPaperRepository>();
  List<ExamQuestionEntity> _questions = const [];
  SubjectPaperProgress? _progress;
  bool _loading = true;
  String get _paperSubjectName => widget.component == null
      ? widget.subject.name
      : _componentDisplayName(
          widget.subject.name,
          widget.component!.componentName,
        );
  String get _progressKey => widget.component == null
      ? '${widget.classItem.id}_${widget.subject.id}'
      : '${widget.classItem.id}_${widget.subject.id}_${widget.component!.id}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final questions = await _repository.getQuestions(
      classId: widget.classItem.id,
      subjectId: widget.subject.id,
      componentId: widget.component?.id ?? '',
    );
    final all = await _repository.getAllProgress();
    if (mounted) {
      setState(() {
        _questions = questions;
        _progress =
            all[_progressKey] ??
            SubjectPaperProgress(
              classId: widget.classItem.id,
              subjectId: widget.subject.id,
              componentId: widget.component?.id ?? '',
            );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _progress ??
        SubjectPaperProgress(
          classId: widget.classItem.id,
          subjectId: widget.subject.id,
          componentId: widget.component?.id ?? '',
        );
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          titleSpacing: 8,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _paperSubjectName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                widget.classItem.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: _copyPreviousPaper,
              icon: const Icon(Icons.copy_all_outlined, size: 18),
              label: const Text('Copy Previous Paper'),
            ),
            const DashboardNavigationButton(),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            tabs: [
              _tab(
                'Objective',
                progress.objectiveStatus,
                progress.objectiveCount,
                progress.objectiveMarks,
              ),
              _tab(
                'Subjective',
                progress.subjectiveStatus,
                progress.subjectiveCount,
                progress.subjectiveMarks,
              ),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [_section(true), _section(false)]),
      ),
    );
  }

  Tab _tab(String title, PaperSectionStatus status, int count, double marks) =>
      Tab(
        height: 52,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            const SizedBox(width: 7),
            _StatusPill(status: status),
            const SizedBox(width: 6),
            Text(
              '$count Q · ${_marks(marks)} M',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      );

  Widget _section(bool objective) {
    final types = ExamQuestionType.values
        .where((e) => e.isObjective == objective)
        .toList();
    final values = _questions.where((q) => q.isObjective == objective).toList();
    final status = objective
        ? _progress!.objectiveStatus
        : _progress!.subjectiveStatus;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  objective
                      ? 'Choose a question type to enter data'
                      : 'Add short or long questions',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF526078),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: values.isEmpty ? null : () => _print(objective),
                icon: const Icon(Icons.print_outlined, size: 17),
                label: Text(objective ? 'Print Objective' : 'Print Subjective'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: values.isEmpty
                    ? null
                    : () => _setComplete(
                        objective,
                        status != PaperSectionStatus.complete,
                      ),
                icon: Icon(
                  status == PaperSectionStatus.complete
                      ? Icons.edit_outlined
                      : Icons.task_alt,
                  size: 17,
                ),
                label: Text(
                  status == PaperSectionStatus.complete
                      ? 'Reopen'
                      : 'Mark Complete',
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 102,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            itemCount: types.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (_, i) => _typeCard(types[i]),
          ),
        ),
        Expanded(
          child: values.isEmpty ? _empty(objective) : _questionList(values),
        ),
      ],
    );
  }

  Widget _typeCard(ExamQuestionType type) {
    final count = _questions.where((q) => q.type == type).length;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: () => _askCount(type),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 145,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDE4F0)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon(type), size: 18, color: _blue),
              const Spacer(),
              Text(
                type.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$count saved · Add',
                style: const TextStyle(fontSize: 9, color: Color(0xFF718096)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(ExamQuestionType type) => switch (type) {
    ExamQuestionType.multipleChoice => Icons.format_list_bulleted,
    ExamQuestionType.fillInTheBlanks => Icons.space_bar,
    ExamQuestionType.matchColumns => Icons.compare_arrows,
    ExamQuestionType.trueFalse => Icons.rule,
    ExamQuestionType.completeSpelling ||
    ExamQuestionType.missingLetter => Icons.spellcheck,
    ExamQuestionType.arrangeCorrectOrder => Icons.reorder,
    ExamQuestionType.labelDiagram => Icons.image_outlined,
    ExamQuestionType.oddOneOut => Icons.filter_4_outlined,
    ExamQuestionType.shortAnswer => Icons.short_text,
    ExamQuestionType.longAnswer => Icons.notes,
  };

  Widget _questionList(List<ExamQuestionEntity> values) => Container(
    margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2E7F0)),
    ),
    child: ListView.separated(
      itemCount: values.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final q = values[i];
        return ListTile(
          dense: true,
          minLeadingWidth: 26,
          leading: Text(
            '${i + 1}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
          title: Text(
            q.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5),
          ),
          subtitle: Text(
            '${q.type.label}${q.cells.isEmpty ? '' : ' · ${q.cells.join(' | ')}'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_marks(q.marks)} M',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () async {
                  await _repository.deleteQuestion(q);
                  await _load();
                },
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _empty(bool objective) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          objective ? Icons.quiz_outlined : Icons.subject_outlined,
          size: 42,
          color: const Color(0xFFB4BECE),
        ),
        const SizedBox(height: 8),
        Text(
          objective
              ? 'No objective questions yet'
              : 'No subjective questions yet',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        const Text(
          'Select a type above to create an entry table.',
          style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
        ),
      ],
    ),
  );

  Future<void> _askCount(ExamQuestionType type) async {
    final controller = TextEditingController(text: '5');
    final count = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type.label),
        content: SizedBox(
          width: 300,
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Number of questions',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text) ?? 0;
              if (value > 0 && value <= 50) Navigator.pop(context, value);
            },
            child: const Text('Create Table'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (count == null || !mounted) return;
    final questions = await showDialog<List<ExamQuestionEntity>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BulkQuestionEditor(
        type: type,
        count: count,
        classItem: widget.classItem,
        subject: widget.subject,
        component: widget.component,
        repository: _repository,
      ),
    );
    if (questions != null) {
      await _repository.saveQuestions(questions);
      await _load();
    }
  }

  Future<void> _setComplete(bool objective, bool complete) async {
    await _repository.setSectionStatus(
      classId: widget.classItem.id,
      subjectId: widget.subject.id,
      componentId: widget.component?.id ?? '',
      objective: objective,
      status: complete ? PaperSectionStatus.complete : PaperSectionStatus.draft,
    );
    await _load();
  }

  Future<void> _copyPreviousPaper() async {
    final source = await showDialog<ExamQuestionPaperEntity>(
      context: context,
      builder: (_) => _PreviousPaperDialog(repository: _repository),
    );
    if (source == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copy previous paper?'),
        content: Text(
          '“${source.title}” ke ${source.questions.length} questions '
          '$_paperSubjectName mein copy honge. Is section ke existing questions replace ho jayenge.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Copy Paper'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final count = await _repository.copyPaperToTarget(
      source: source,
      classId: widget.classItem.id,
      className: widget.classItem.name,
      subjectId: widget.subject.id,
      subjectName: widget.subject.name,
      componentId: widget.component?.id ?? '',
      componentName: widget.component?.componentName ?? '',
    );
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count questions copied as Draft.')),
      );
    }
  }

  Future<void> _print(bool objective) async {
    final questions = _questions
        .where((question) => question.isObjective == objective)
        .toList();
    if (questions.isEmpty) return;
    final branding = await sl<GetSchoolSettings>()();
    if (!mounted) return;
    final totalMarks = questions.fold<double>(
      0,
      (total, question) => total + question.marks,
    );
    final setup = await showDialog<_PaperPrintSetup>(
      context: context,
      builder: (_) => _PaperPrintSetupDialog(
        schoolName: branding.schoolName,
        logoUrl: branding.logoUrl,
        className: _classDisplayName(widget.classItem.name),
        subjectName: _paperSubjectName,
        objective: objective,
        totalMarks: totalMarks,
      ),
    );
    if (setup == null) return;
    final paper = ExamQuestionPaperEntity(
      id: _repository.newPaperId(),
      title: setup.examName,
      schoolName: branding.schoolName,
      logoUrl: branding.logoUrl,
      classId: widget.classItem.id,
      className: _classDisplayName(widget.classItem.name),
      subjectId: widget.subject.id,
      subjectName: widget.subject.name,
      componentId: widget.component?.id ?? '',
      componentName: widget.component?.componentName ?? '',
      durationMinutes: setup.durationMinutes,
      passingMarks: objective ? 0 : setup.passingMarks,
      questions: questions,
      instructions: setup.instructions,
      createdAt: DateTime.now(),
    );
    await _repository.savePaper(paper);
    await Printing.layoutPdf(
      name: '${setup.examName}.pdf',
      onLayout: (_) => QuestionPaperPdfService().build(paper),
    );
  }
}

class _PreviousPaperDialog extends StatefulWidget {
  const _PreviousPaperDialog({required this.repository});
  final QuestionPaperRepository repository;
  @override
  State<_PreviousPaperDialog> createState() => _PreviousPaperDialogState();
}

class _PreviousPaperDialogState extends State<_PreviousPaperDialog> {
  final _search = TextEditingController();
  late final Future<List<ExamQuestionPaperEntity>> _papers;

  @override
  void initState() {
    super.initState();
    _papers = widget.repository.getSavedPapers();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: 760,
      height: 620,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
            color: const Color(0xFFF1F5FF),
            child: Row(
              children: [
                const Icon(Icons.history_outlined, color: _blue),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Copy Previous Paper',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Select any saved class, exam, objective or subjective paper.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF60708A),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search exam, class or subject',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ExamQuestionPaperEntity>>(
              future: _papers,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Previous papers could not be loaded: ${snapshot.error}',
                    ),
                  );
                }
                final query = _search.text.trim().toLowerCase();
                final papers = (snapshot.data ?? const []).where((paper) {
                  final value =
                      '${paper.title} ${paper.className} ${_paperName(paper)}'
                          .toLowerCase();
                  return query.isEmpty || value.contains(query);
                }).toList();
                if (papers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No saved papers found. Generate a PDF once to save it in history.',
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: papers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (_, index) {
                    final paper = papers[index];
                    final objective = paper.questions.every(
                      (q) => q.isObjective,
                    );
                    final subjective = paper.questions.every(
                      (q) => !q.isObjective,
                    );
                    final kind = objective
                        ? 'Objective'
                        : subjective
                        ? 'Subjective'
                        : 'Mixed';
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: () => Navigator.pop(context, paper),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFDDE4F0)),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF0FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: _blue,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      paper.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${paper.className} · ${_paperName(paper)} · $kind',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF60708A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${paper.questions.length} Q · ${_marks(paper.totalMarks)} M',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _blue,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _date(paper.createdAt),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF8491A5),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF718096),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  static String _paperName(ExamQuestionPaperEntity paper) =>
      paper.componentName.isEmpty
      ? paper.subjectName
      : _componentDisplayName(paper.subjectName, paper.componentName);
  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
}

class _PaperPrintSetup {
  const _PaperPrintSetup({
    required this.examName,
    required this.durationMinutes,
    required this.instructions,
    required this.passingMarks,
  });
  final String examName, instructions;
  final int durationMinutes;
  final double passingMarks;
}

class _PaperPrintSetupDialog extends StatefulWidget {
  const _PaperPrintSetupDialog({
    required this.schoolName,
    required this.logoUrl,
    required this.className,
    required this.subjectName,
    required this.objective,
    required this.totalMarks,
  });
  final String schoolName, logoUrl, className, subjectName;
  final bool objective;
  final double totalMarks;
  @override
  State<_PaperPrintSetupDialog> createState() => _PaperPrintSetupDialogState();
}

class _PaperPrintSetupDialogState extends State<_PaperPrintSetupDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _exam;
  final _time = TextEditingController(text: '120');
  final _instructions = TextEditingController(text: 'Attempt all questions.');
  final _passing = TextEditingController();

  @override
  void initState() {
    super.initState();
    _exam = TextEditingController(
      text:
          '${widget.subjectName} ${widget.objective ? 'Objective' : 'Subjective'} Paper',
    );
    if (!widget.objective) {
      _passing.text = (widget.totalMarks * .4).round().toString();
    }
  }

  @override
  void dispose() {
    _exam.dispose();
    _time.dispose();
    _instructions.dispose();
    _passing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: [
        const Icon(Icons.print_outlined, color: _blue),
        const SizedBox(width: 8),
        Text('Print ${widget.objective ? 'Objective' : 'Subjective'} Paper'),
      ],
    ),
    content: SizedBox(
      width: 620,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    if (widget.logoUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Image.network(
                          widget.logoUrl,
                          width: 42,
                          height: 42,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.school_outlined, size: 34),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(
                          Icons.school_outlined,
                          size: 34,
                          color: _blue,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.schoolName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Text(
                            'School name and logo from Branding Settings',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 390,
                    child: _field(_exam, 'Exam Name', required: true),
                  ),
                  SizedBox(
                    width: 180,
                    child: _field(
                      _time,
                      'Total Time (minutes)',
                      number: true,
                      required: true,
                    ),
                  ),
                  _readOnlyBox('Class', widget.className, 180),
                  _readOnlyBox('Subject', widget.subjectName, 200),
                  _readOnlyBox('Total Marks', _marks(widget.totalMarks), 150),
                  if (!widget.objective)
                    SizedBox(
                      width: 180,
                      child: _field(
                        _passing,
                        'Passing Marks',
                        number: true,
                        required: true,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _field(_instructions, 'Instructions', maxLines: 2),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Generate PDF'),
      ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
    bool required = false,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    validator: required
        ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
        : null,
  );

  Widget _readOnlyBox(String label, String value, double width) => SizedBox(
    width: width,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final time = int.tryParse(_time.text) ?? 0;
    final passing = double.tryParse(_passing.text) ?? 0;
    if (time <= 0 ||
        (!widget.objective && (passing < 0 || passing > widget.totalMarks))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid time and passing marks.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _PaperPrintSetup(
        examName: _exam.text.trim(),
        durationMinutes: time,
        instructions: _instructions.text.trim(),
        passingMarks: passing,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final PaperSectionStatus status;
  @override
  Widget build(BuildContext context) {
    final color = status == PaperSectionStatus.complete
        ? const Color(0xFF14804A)
        : status == PaperSectionStatus.draft
        ? const Color(0xFFB76E00)
        : const Color(0xFF718096);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _BulkQuestionEditor extends StatefulWidget {
  const _BulkQuestionEditor({
    required this.type,
    required this.count,
    required this.classItem,
    required this.subject,
    required this.repository,
    this.component,
  });
  final ExamQuestionType type;
  final int count;
  final AcademicClassEntity classItem;
  final AcademicSubjectEntity subject;
  final QuestionPaperRepository repository;
  final SubjectComponentEntity? component;
  @override
  State<_BulkQuestionEditor> createState() => _BulkQuestionEditorState();
}

class _BulkQuestionEditorState extends State<_BulkQuestionEditor> {
  late final List<_EntryRow> _rows;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _rows = List.generate(
      widget.count,
      (_) => _EntryRow(cellCount: _cellLabels(widget.type).length),
    );
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  static List<String> _cellLabels(ExamQuestionType type) => switch (type) {
    ExamQuestionType.multipleChoice => [
      'Option A',
      'Option B',
      'Option C',
      'Option D',
    ],
    ExamQuestionType.matchColumns => ['Column B'],
    ExamQuestionType.oddOneOut => ['Item A', 'Item B', 'Item C', 'Item D'],
    ExamQuestionType.labelDiagram => const [],
    ExamQuestionType.completeSpelling ||
    ExamQuestionType.missingLetter => ['Hint / image (optional)'],
    _ => const [],
  };

  @override
  Widget build(BuildContext context) {
    final labels = _cellLabels(widget.type);
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: SizedBox(
        width: 1180,
        height: 650,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.table_chart_outlined, color: _blue),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.type.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${widget.classItem.name} · ${widget.component?.componentName ?? widget.subject.name} · ${widget.count} rows',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF60708A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Container(
              height: 38,
              color: const Color(0xFF263B68),
              child: Row(
                children: [
                  _head('#', 42),
                  if (widget.type != ExamQuestionType.labelDiagram)
                    _head(
                      widget.type.promptLabel,
                      labels.isEmpty ? 0 : 330,
                      flex: labels.isEmpty ? 1 : 0,
                    ),
                  if (widget.type == ExamQuestionType.labelDiagram)
                    _head('Picture', 0, flex: 1),
                  ...labels.map((e) => _head(e, 150)),
                  _head('Marks', 72),
                  if (!widget.type.isObjective) _head('Lines', 72),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) => _entryRow(i, labels),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE1E6EF))),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF718096),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Correct answers are not required. Data is used only for A4 paper printing.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF718096)),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      _saving
                          ? 'Uploading...'
                          : 'Save ${widget.count} Questions',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _head(String text, double width, {int flex = 0}) {
    final child = Container(
      width: flex == 0 ? width : null,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return flex > 0 ? Expanded(child: child) : child;
  }

  Widget _entryRow(int index, List<String> labels) {
    final row = _rows[index];
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (widget.type == ExamQuestionType.labelDiagram)
            Expanded(child: _picturePicker(row))
          else if (labels.isEmpty)
            Expanded(child: _input(row.prompt, widget.type.promptLabel))
          else
            SizedBox(
              width: 330,
              child: _input(row.prompt, widget.type.promptLabel),
            ),
          ...row.cells.map(
            (controller) => SizedBox(width: 150, child: _input(controller, '')),
          ),
          SizedBox(width: 72, child: _input(row.marks, '1', number: true)),
          if (!widget.type.isObjective)
            SizedBox(width: 72, child: _input(row.lines, '0', number: true)),
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
    child: TextField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _picturePicker(_EntryRow row) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    child: Row(
      children: [
        OutlinedButton.icon(
          onPressed: _saving ? null : () => _pickPicture(row),
          icon: const Icon(Icons.upload_file_outlined, size: 18),
          label: Text(
            row.imageBytes == null ? 'Upload Picture' : 'Change Picture',
          ),
        ),
        const SizedBox(width: 10),
        if (row.imageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.memory(
              row.imageBytes!,
              width: 62,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.imageName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF526078)),
            ),
          ),
          IconButton(
            tooltip: 'Remove picture',
            onPressed: () => setState(() {
              row.imageBytes = null;
              row.imageName = '';
            }),
            icon: const Icon(Icons.close, size: 17),
          ),
        ] else
          const Text(
            'PNG or JPG · teacher-prepared lines/markers',
            style: TextStyle(fontSize: 11, color: Color(0xFF8491A5)),
          ),
      ],
    ),
  );

  Future<void> _pickPicture(_EntryRow row) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null || !mounted) return;
    setState(() {
      row.imageBytes = file!.bytes;
      row.imageName = file.name;
    });
  }

  Future<void> _save() async {
    if (widget.type != ExamQuestionType.labelDiagram &&
        _rows.any((row) => row.prompt.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter every question/prompt.')),
      );
      return;
    }
    if (widget.type == ExamQuestionType.labelDiagram &&
        _rows.any((row) => row.imageBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a picture for every row.')),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final questions = <ExamQuestionEntity>[];
    for (final entry in _rows.asMap().entries) {
      final row = entry.value;
      var imageUrl = '';
      if (row.imageBytes != null) {
        try {
          imageUrl = await widget.repository.uploadDiagram(
            bytes: row.imageBytes!,
            fileName: row.imageName,
          );
        } catch (error) {
          if (mounted) {
            setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Picture upload failed: $error')),
            );
          }
          return;
        }
      }
      questions.add(
        ExamQuestionEntity(
          id: widget.repository.newQuestionId(),
          classId: widget.classItem.id,
          className: widget.classItem.name,
          subjectId: widget.subject.id,
          subjectName: widget.subject.name,
          componentId: widget.component?.id ?? '',
          componentName: widget.component?.componentName ?? '',
          type: widget.type,
          text: widget.type == ExamQuestionType.labelDiagram
              ? 'Label the diagram.'
              : row.prompt.text.trim(),
          marks: double.tryParse(row.marks.text) ?? 1,
          cells: row.cells.map((e) => e.text.trim()).toList(),
          imageUrl: imageUrl,
          answerLines: int.tryParse(row.lines.text) ?? 0,
          createdAt: now.add(Duration(milliseconds: entry.key)),
        ),
      );
    }
    if (!mounted) return;
    Navigator.pop(context, questions);
  }
}

class _EntryRow {
  _EntryRow({required int cellCount})
    : cells = List.generate(cellCount, (_) => TextEditingController());
  final prompt = TextEditingController();
  final marks = TextEditingController(text: '1');
  final lines = TextEditingController(text: '0');
  final List<TextEditingController> cells;
  Uint8List? imageBytes;
  String imageName = '';
  void dispose() {
    prompt.dispose();
    marks.dispose();
    lines.dispose();
    for (final cell in cells) {
      cell.dispose();
    }
  }
}

String _marks(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String _componentDisplayName(String subjectName, String componentName) {
  final subject = subjectName.trim();
  final component = componentName.trim();
  if (component.toLowerCase().startsWith(subject.toLowerCase())) {
    return component;
  }
  return '$subject $component'.trim();
}

String _classDisplayName(String className) {
  final name = className.trim();
  if (name.toLowerCase().startsWith('class ')) return name;
  return 'Class $name';
}
