import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../teachers/domain/entities/teacher_assignment_entity.dart';
import '../../../teachers/domain/repositories/teacher_assignment_repository.dart';
import '../../domain/entities/exam_date_sheet_entity.dart';
import '../../domain/entities/exam_date_sheet_validation_entity.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/repositories/exam_date_sheet_repository.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../domain/usecases/validate_exam_date_sheet.dart';

class ManualExamDateSheetBuilderPage extends StatefulWidget {
  const ManualExamDateSheetBuilderPage({super.key, this.existing});

  final ExamDateSheetEntity? existing;

  @override
  State<ManualExamDateSheetBuilderPage> createState() =>
      _ManualExamDateSheetBuilderPageState();
}

class _ManualExamDateSheetBuilderPageState
    extends State<ManualExamDateSheetBuilderPage> {
  final _titleController = TextEditingController();
  List<ExamEntity> _exams = const [];
  List<AcademicClassEntity> _classes = const [];
  List<SectionEntity> _sections = const [];
  List<AcademicSubjectEntity> _subjects = const [];
  List<TeacherAssignmentEntity> _assignments = const [];
  List<ExamDateSheetPaperEntity> _papers = const [];

  String? _examId;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final _validator = const ValidateExamDateSheet();
  ExamDateSheetValidationResult? _validationResult;
  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _examId = existing.examId;
      _papers = List<ExamDateSheetPaperEntity>.of(existing.papers);
    }
    _loadReferences();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    try {
      final values = await Future.wait<Object?>([
        sl<ExamRepository>().getExams(),
        sl<AcademicStructureRepository>().getClasses(),
        sl<AcademicStructureRepository>().getSections(),
        sl<AcademicStructureRepository>().getSubjects(),
        sl<TeacherAssignmentRepository>().getAssignments(),
      ]);

      if (!mounted) return;

      final exams = (values[0] as List<ExamEntity>)
          .where((exam) => exam.isActive)
          .toList();
      final classes =
          (values[1] as List<AcademicClassEntity>)
              .where((item) => item.isActive)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      final sections =
          (values[2] as List<SectionEntity>)
              .where((item) => item.isActive)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      final subjects =
          (values[3] as List<AcademicSubjectEntity>)
              .where((item) => item.isActive)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _exams = exams;
        _classes = classes;
        _sections = sections;
        _subjects = subjects;
        _assignments = values[4] as List<TeacherAssignmentEntity>;
        _examId ??= exams.isEmpty ? null : exams.first.id;
        if (_titleController.text.trim().isEmpty && _selectedExam != null) {
          _titleController.text = '${_selectedExam!.name} Date Sheet';
        }
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _message(error);
      });
    }
  }

  bool get _isReadOnly =>
      widget.existing != null &&
      widget.existing!.status != ExamDateSheetStatus.draft;
  ExamEntity? get _selectedExam {
    for (final exam in _exams) {
      if (exam.id == _examId) return exam;
    }
    return null;
  }

  Future<void> _addPaper([ExamDateSheetPaperEntity? existing]) async {
    final exam = _selectedExam;
    if (exam == null) {
      _show('Select an exam first.');
      return;
    }

    final result = await showDialog<ExamDateSheetPaperEntity>(
      context: context,
      builder: (_) => _PaperEditorDialog(
        exam: exam,
        classes: _classes,
        sections: _sections,
        subjects: _subjects,
        assignments: _assignments,
        existing: existing,
      ),
    );

    if (!mounted || result == null) return;

    final candidate = _papers.where((item) => item.id != existing?.id).toList()
      ..add(result);

    final conflict = _validatePapers(candidate, exam);
    if (conflict != null) {
      _show(conflict);
      return;
    }

    candidate.sort((a, b) {
      final date = a.examDate.compareTo(b.examDate);
      if (date != 0) return date;
      final time = a.startMinutes.compareTo(b.startMinutes);
      if (time != 0) return time;
      return a.className.compareTo(b.className);
    });

    setState(() {
      _papers = candidate;
      _validationResult = null;
    });
  }

  String? _validatePapers(
    List<ExamDateSheetPaperEntity> papers,
    ExamEntity exam,
  ) {
    final result = _validator(exam: exam, papers: papers);
    _validationResult = result;
    return result.errors.isEmpty ? null : result.errors.first.message;
  }

  void _runValidation() {
    final exam = _selectedExam;
    if (exam == null) {
      _show('Select an exam first.');
      return;
    }

    setState(() {
      _validationResult = _validator(exam: exam, papers: _papers);
    });
  }

  Future<void> _showValidationDetails() async {
    if (_validationResult == null) {
      _runValidation();
    }

    final current = _validationResult;
    if (current == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Date Sheet Validation'),
        content: SizedBox(
          width: 720,
          child: current.issues.isEmpty
              ? const _ValidationSuccess()
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: current.issues.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final issue = current.issues[index];
                    final isError =
                        issue.severity == ExamDateSheetIssueSeverity.error;

                    return ListTile(
                      leading: Icon(
                        isError
                            ? Icons.error_outline
                            : Icons.warning_amber_outlined,
                        color: isError
                            ? Theme.of(context).colorScheme.error
                            : const Color(0xFFF57C00),
                      ),
                      title: Text(issue.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(issue.message),
                          const SizedBox(height: 4),
                          Text(
                            'Suggested fix: ${issue.suggestion}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_isReadOnly) {
      _show(
        'Published or archived date sheets are read-only. Create a revision draft to edit.',
      );
      return;
    }
    final exam = _selectedExam;
    if (exam == null) {
      _show('Select an exam.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _show('Date sheet title is required.');
      return;
    }
    if (_papers.isEmpty) {
      _show('Add at least one paper.');
      return;
    }

    final conflict = _validatePapers(_papers, exam);
    if (conflict != null) {
      _show(conflict);
      return;
    }

    setState(() => _saving = true);
    try {
      final repository = sl<ExamDateSheetRepository>();
      final now = DateTime.now();
      final existing = widget.existing;

      await repository.saveDateSheet(
        ExamDateSheetEntity(
          id: existing?.id ?? repository.generateDateSheetId(),
          examId: exam.id,
          examName: exam.name,
          academicSession: exam.academicSession,
          title: _titleController.text.trim(),
          creationMode: ExamDateSheetCreationMode.manual,
          status: existing?.status ?? ExamDateSheetStatus.draft,
          papers: _papers,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
          publishedAt: existing?.publishedAt,
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _show(_message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? 'Manual Date Sheet Builder'
              : 'Edit Manual Date Sheet',
        ),
        actions: [const DashboardNavigationButton(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _loading || _saving || _isReadOnly ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Draft'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading || _saving || _isReadOnly
            ? null
            : () => _addPaper(),
        icon: const Icon(Icons.add),
        label: const Text('Add Paper'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_isReadOnly) ...[
                    Card(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This date sheet is read-only. Use Publish Workflow â†’ Revise to create an editable draft.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          SizedBox(
                            width: 320,
                            child: DropdownButtonFormField<String>(
                              initialValue: _examId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Exam',
                                border: OutlineInputBorder(),
                              ),
                              items: _exams
                                  .map(
                                    (exam) => DropdownMenuItem(
                                      value: exam.id,
                                      child: Text(exam.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: widget.existing != null
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _examId = value;
                                        _papers = const [];
                                        final exam = _selectedExam;
                                        if (exam != null) {
                                          _titleController.text =
                                              '${exam.name} Date Sheet';
                                        }
                                      });
                                    },
                            ),
                          ),
                          SizedBox(
                            width: 360,
                            child: TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Date Sheet Title',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          if (_selectedExam != null)
                            Chip(
                              avatar: const Icon(
                                Icons.date_range_outlined,
                                size: 18,
                              ),
                              label: Text(
                                '${_date(_selectedExam!.startDate ?? _selectedExam!.examDate)}'
                                ' - '
                                '${_date(_selectedExam!.endDate ?? _selectedExam!.examDate)}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ValidationPanel(
                    result: _validationResult,
                    paperCount: _papers.length,
                    onValidate: _runValidation,
                    onDetails: _showValidationDetails,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _papers.isEmpty
                        ? const Center(
                            child: Text('No papers added. Click "Add Paper".'),
                          )
                        : Card(
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Day')),
                                    DataColumn(label: Text('Class')),
                                    DataColumn(label: Text('Section')),
                                    DataColumn(label: Text('Subject')),
                                    DataColumn(label: Text('Teacher')),
                                    DataColumn(label: Text('Time')),
                                    DataColumn(label: Text('Marks')),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: [
                                    for (final paper in _papers)
                                      DataRow(
                                        cells: [
                                          DataCell(Text(_date(paper.examDate))),
                                          DataCell(Text(_day(paper.examDate))),
                                          DataCell(Text(paper.className)),
                                          DataCell(Text(paper.sectionName)),
                                          DataCell(Text(paper.subjectName)),
                                          DataCell(Text(paper.teacherName)),
                                          DataCell(
                                            Text(
                                              '${_time(paper.startMinutes)} - ${_time(paper.endMinutes)}',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '${paper.totalMarks.toStringAsFixed(0)} / ${paper.passingMarks.toStringAsFixed(0)}',
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  tooltip: 'Edit',
                                                  onPressed: () =>
                                                      _addPaper(paper),
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Delete',
                                                  onPressed: () {
                                                    setState(() {
                                                      _papers = _papers
                                                          .where(
                                                            (item) =>
                                                                item.id !=
                                                                paper.id,
                                                          )
                                                          .toList();
                                                    });
                                                  },
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';

  static String _day(DateTime value) => switch (value.weekday) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    DateTime.sunday => 'Sunday',
    _ => '',
  };

  static String _time(int value) {
    final hour = value ~/ 60;
    final minute = value % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$display:${minute.toString().padLeft(2, '0')} $suffix';
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}

class _ValidationPanel extends StatelessWidget {
  const _ValidationPanel({
    required this.result,
    required this.paperCount,
    required this.onValidate,
    required this.onDetails,
  });

  final ExamDateSheetValidationResult? result;
  final int paperCount;
  final VoidCallback onValidate;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final value = result;
    final color = value == null
        ? Theme.of(context).colorScheme.primary
        : value.isValid
        ? const Color(0xFF00897B)
        : Theme.of(context).colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 14,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.fact_check_outlined, color: color),
            Text(
              'Validation Score',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Chip(
              label: Text(
                value == null ? 'Not Checked' : '${value.score} / 100',
              ),
              backgroundColor: color.withAlpha(24),
            ),
            if (value != null) ...[
              Chip(
                avatar: const Icon(Icons.check_circle_outline, size: 17),
                label: Text('${value.validPaperCount} valid'),
              ),
              Chip(
                avatar: const Icon(Icons.warning_amber_outlined, size: 17),
                label: Text('${value.warnings.length} warnings'),
              ),
              Chip(
                avatar: const Icon(Icons.error_outline, size: 17),
                label: Text('${value.errors.length} conflicts'),
              ),
              Chip(label: Text(value.rating)),
            ] else
              Text('$paperCount papers ready to validate'),
            OutlinedButton.icon(
              onPressed: onValidate,
              icon: const Icon(Icons.rule_outlined),
              label: const Text('Validate'),
            ),
            if (value != null)
              TextButton.icon(
                onPressed: onDetails,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View Details'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ValidationSuccess extends StatelessWidget {
  const _ValidationSuccess();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 56, color: Color(0xFF00897B)),
          SizedBox(height: 12),
          Text(
            'No conflicts or warnings found.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PaperEditorDialog extends StatefulWidget {
  const _PaperEditorDialog({
    required this.exam,
    required this.classes,
    required this.sections,
    required this.subjects,
    required this.assignments,
    this.existing,
  });

  final ExamEntity exam;
  final List<AcademicClassEntity> classes;
  final List<SectionEntity> sections;
  final List<AcademicSubjectEntity> subjects;
  final List<TeacherAssignmentEntity> assignments;
  final ExamDateSheetPaperEntity? existing;

  @override
  State<_PaperEditorDialog> createState() => _PaperEditorDialogState();
}

class _PaperEditorDialogState extends State<_PaperEditorDialog> {
  String? _classId;
  String? _sectionId;
  String? _subjectId;
  String? _teacherId;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late TextEditingController _total;
  late TextEditingController _passing;
  late TextEditingController _instructions;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _classId =
        existing?.classId ??
        (widget.classes.isEmpty ? null : widget.classes.first.id);
    _sectionId = existing?.sectionId ?? _firstSectionId(_classId);
    _subjectId = existing?.subjectId ?? _firstSubjectId();
    _teacherId = existing?.teacherId ?? _firstTeacherId();
    _date = existing?.examDate ?? widget.exam.startDate ?? widget.exam.examDate;
    _start = _toTime(existing?.startMinutes ?? 540);
    _end = _toTime(existing?.endMinutes ?? 660);
    _total = TextEditingController(
      text: '${existing?.totalMarks ?? widget.exam.totalMarks}',
    );
    _passing = TextEditingController(
      text: '${existing?.passingMarks ?? widget.exam.passingMarks}',
    );
    _instructions = TextEditingController(text: existing?.instructions ?? '');
  }

  @override
  void dispose() {
    _total.dispose();
    _passing.dispose();
    _instructions.dispose();
    super.dispose();
  }

  List<SectionEntity> get _availableSections =>
      widget.sections.where((item) => item.classId == _classId).toList();

  List<AcademicSubjectEntity> get _availableSubjects {
    final byName = <String, AcademicSubjectEntity>{};
    for (final subject in widget.subjects) {
      if (subject.classId == _classId && subject.sectionId == null) {
        byName[_normalise(subject.name)] = subject;
      }
    }
    for (final subject in widget.subjects) {
      if (subject.classId == _classId && subject.sectionId == _sectionId) {
        byName[_normalise(subject.name)] = subject;
      }
    }
    return byName.values.toList();
  }

  List<TeacherAssignmentEntity> get _availableTeachers {
    final className = _class?.name ?? '';
    final sectionName = _section?.name ?? '';
    final subjectName = _subject?.name ?? '';

    return widget.assignments.where((assignment) {
      final classMatches =
          assignment.classId == _classId ||
          _normalise(assignment.classId) == _normalise(className);
      final sectionMatches =
          assignment.sectionId == _sectionId ||
          _normalise(assignment.sectionId) == _normalise(sectionName);
      return classMatches &&
          sectionMatches &&
          _normalise(assignment.subject) == _normalise(subjectName) &&
          _normalise(assignment.academicSession) ==
              _normalise(widget.exam.academicSession);
    }).toList();
  }

  AcademicClassEntity? get _class =>
      widget.classes.where((item) => item.id == _classId).firstOrNull;
  SectionEntity? get _section =>
      widget.sections.where((item) => item.id == _sectionId).firstOrNull;
  AcademicSubjectEntity? get _subject =>
      widget.subjects.where((item) => item.id == _subjectId).firstOrNull;
  TeacherAssignmentEntity? get _teacher => widget.assignments
      .where((item) => item.teacherId == _teacherId)
      .firstOrNull;

  String? _firstSectionId(String? classId) {
    for (final item in widget.sections) {
      if (item.classId == classId) return item.id;
    }
    return null;
  }

  String? _firstSubjectId() {
    final values = _availableSubjects;
    return values.isEmpty ? null : values.first.id;
  }

  String? _firstTeacherId() {
    final values = _availableTeachers;
    return values.isEmpty ? null : values.first.teacherId;
  }

  Future<void> _pickDate() async {
    final start = widget.exam.startDate ?? widget.exam.examDate;
    final end = widget.exam.endDate ?? widget.exam.examDate;
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: start,
      lastDate: end,
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _pickTime(bool start) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (value == null) return;
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Paper' : 'Edit Paper'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: _classId,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.classes
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _classId = value;
                      _sectionId = _firstSectionId(value);
                      _subjectId = _firstSubjectId();
                      _teacherId = _firstTeacherId();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _sectionId,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableSections
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _sectionId = value;
                      _subjectId = _firstSubjectId();
                      _teacherId = _firstTeacherId();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: _subjectId,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableSubjects
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _subjectId = value;
                      _teacherId = _firstTeacherId();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String>(
                  initialValue: _teacherId,
                  decoration: const InputDecoration(
                    labelText: 'Teacher',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableTeachers
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.teacherId,
                          child: Text(item.teacherName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _teacherId = value),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  '${_date.day.toString().padLeft(2, '0')}/'
                  '${_date.month.toString().padLeft(2, '0')}/'
                  '${_date.year}',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickTime(true),
                icon: const Icon(Icons.schedule),
                label: Text('Start: ${_start.format(context)}'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickTime(false),
                icon: const Icon(Icons.schedule),
                label: Text('End: ${_end.format(context)}'),
              ),
              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: _total,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Marks',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: _passing,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Passing Marks',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 690,
                child: TextFormField(
                  controller: _instructions,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              _class == null ||
                  _section == null ||
                  _subject == null ||
                  _teacher == null
              ? null
              : () {
                  final repository = sl<ExamDateSheetRepository>();
                  Navigator.pop(
                    context,
                    ExamDateSheetPaperEntity(
                      id: widget.existing?.id ?? repository.generatePaperId(),
                      classId: _class!.id,
                      className: _class!.name,
                      sectionId: _section!.id,
                      sectionName: _section!.name,
                      subjectId: _subject!.id,
                      subjectName: _subject!.name,
                      teacherId: _teacher!.teacherId,
                      teacherName: _teacher!.teacherName,
                      examDate: _date,
                      startMinutes: _start.hour * 60 + _start.minute,
                      endMinutes: _end.hour * 60 + _end.minute,
                      totalMarks: double.tryParse(_total.text) ?? 0,
                      passingMarks: double.tryParse(_passing.text) ?? 0,
                      instructions: _instructions.text.trim(),
                    ),
                  );
                },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  static TimeOfDay _toTime(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  static String _normalise(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
