import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../../core/widgets/manual_date_picker.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/entities/subject_component_entity.dart';
import '../../../academic_structure/domain/repositories/subject_component_repository.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/entities/exam_subject_setup_entity.dart';
import '../../domain/repositories/exam_subject_setup_repository.dart';
import '../../domain/usecases/generate_exam_id.dart';
import '../bloc/exam_subject_setup_bloc.dart';
import '../bloc/exam_subject_setup_event.dart';
import '../bloc/exam_subject_setup_state.dart';

enum _ComponentPassingMode { combined, componentWise }

class ExamFormPage extends StatelessWidget {
  const ExamFormPage({super.key, this.exam});

  final ExamEntity? exam;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ExamSubjectSetupBloc>()..add(LoadExamConfiguration(exam)),
      child: _ExamFormView(exam: exam),
    );
  }
}

class _ExamFormView extends StatefulWidget {
  const _ExamFormView({this.exam});

  final ExamEntity? exam;

  @override
  State<_ExamFormView> createState() => _ExamFormViewState();
}

class _ExamFormViewState extends State<_ExamFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _sessionController;
  late final TextEditingController _descriptionController;
  final _commonTotalController = TextEditingController(text: '100');
  final _commonPassingController = TextEditingController(text: '33');
  final Map<String, _SubjectDraft> _drafts = {};
  final Set<String> _selectedSectionIds = {};
  List<SubjectComponentEntity> _components = const [];
  bool _componentsLoading = true;
  late ExamType _type;
  late ExamWorkflowStatus _status;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _resultDate;
  bool _initialized = false;
  bool _isSaving = false;

  bool get _isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    final exam = widget.exam;
    _nameController = TextEditingController(text: exam?.name ?? '');
    _sessionController = TextEditingController(
      text: exam?.academicSession ?? '',
    );
    _descriptionController = TextEditingController(
      text: exam?.description ?? '',
    );
    _type = exam?.type ?? ExamType.monthly;
    _status = exam?.status ?? ExamWorkflowStatus.draft;
    _startDate = exam?.startDate;
    _endDate = exam?.endDate;
    _resultDate = exam?.resultDate;
    _loadComponents();
  }

  Future<void> _loadComponents() async {
    try {
      final values = await sl<SubjectComponentRepository>().getComponents();
      if (!mounted) return;
      setState(() {
        _components = values.where((item) => item.isActive).toList()
          ..sort(
            (first, second) =>
                first.displayOrder.compareTo(second.displayOrder),
          );
        _componentsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _componentsLoading = false);
      _showMessage('Subject components could not be loaded: $error');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sessionController.dispose();
    _descriptionController.dispose();
    _commonTotalController.dispose();
    _commonPassingController.dispose();
    for (final draft in _drafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  void _initializeConfiguration(ExamConfigurationLoaded data) {
    if (_initialized) return;
    _initialized = true;
    final active = data.existingSetups.where((item) => item.isActive);
    _selectedSectionIds.addAll(active.map((item) => item.sectionId));
    for (final setup in active) {
      final subject = data.subjects
          .where(
            (item) =>
                item.id == setup.subjectId ||
                item.name.toLowerCase() == setup.subjectName.toLowerCase(),
          )
          .firstOrNull;
      final academicClass = data.classes
          .where(
            (item) =>
                item.id == setup.classId ||
                item.name.toLowerCase() == setup.className.toLowerCase(),
          )
          .firstOrNull;
      final section = data.sections
          .where(
            (item) =>
                (item.id == setup.sectionId ||
                    item.name.toLowerCase() ==
                        setup.sectionName.toLowerCase()) &&
                item.classId == academicClass?.id,
          )
          .firstOrNull;
      if (subject == null || academicClass == null || section == null) continue;
      _drafts[_key(
        widget.exam!.id,
        academicClass.id,
        section.id,
        subject.id,
      )] = _SubjectDraft(
        academicClass: academicClass,
        section: section,
        subject: subject,
        selected: true,
        totalMarks: setup.totalMarks,
        passingMarks: setup.passingMarks,
        existing: setup,
        components: _componentsFor(subject),
        componentTotalMarks: setup.componentTotalMarks,
        componentPassingMarks: setup.componentPassingMarks,
        componentPassingMode: setup.componentPassingMarks.isEmpty
            ? _ComponentPassingMode.combined
            : _ComponentPassingMode.componentWise,
      );
    }
  }

  List<AcademicSubjectEntity> _subjectsFor(
    ExamConfigurationLoaded data,
    SectionEntity section,
  ) {
    final sectionSubjects = data.subjects
        .where(
          (item) =>
              item.classId == section.classId && item.sectionId == section.id,
        )
        .toList(growable: false);
    if (sectionSubjects.isNotEmpty) return sectionSubjects;
    return data.subjects
        .where(
          (item) => item.classId == section.classId && item.sectionId == null,
        )
        .toList(growable: false);
  }

  List<SubjectComponentEntity> _componentsFor(AcademicSubjectEntity subject) {
    if (!subject.useComponentsInExamination) return const [];
    return _components
        .where((item) => item.parentSubjectId == subject.id && item.isActive)
        .toList(growable: false);
  }

  void _distributeDraftEqually(_SubjectDraft draft) {
    if (draft.components.isEmpty) return;

    final total = double.tryParse(draft.totalController.text.trim()) ?? 0;
    final totalEach = total / draft.components.length;

    for (final component in draft.components) {
      draft.componentTotalControllers[component.id]!.text = _marksText(
        totalEach,
      );
    }
  }

  String _key(
    String examId,
    String classId,
    String sectionId,
    String subjectId,
  ) => '${examId}_${classId}_${sectionId}_$subjectId';

  void _setSectionSelected(
    ExamConfigurationLoaded data,
    AcademicClassEntity academicClass,
    SectionEntity section,
    bool selected,
  ) {
    final examId = widget.exam?.id ?? '';
    setState(() {
      if (selected) {
        _selectedSectionIds.add(section.id);
      } else {
        _selectedSectionIds.remove(section.id);
      }
      for (final subject in _subjectsFor(data, section)) {
        final key = _key(examId, academicClass.id, section.id, subject.id);
        final existing = data.existingSetups
            .where((item) => item.uniqueKey == key)
            .firstOrNull;
        final draft = _drafts.putIfAbsent(
          key,
          () => _SubjectDraft(
            academicClass: academicClass,
            section: section,
            subject: subject,
            selected: selected,
            totalMarks: existing?.totalMarks ?? 100,
            passingMarks: existing?.passingMarks ?? 33,
            existing: existing,
            components: _componentsFor(subject),
            componentTotalMarks: existing?.componentTotalMarks ?? const {},
            componentPassingMarks: existing?.componentPassingMarks ?? const {},
            componentPassingMode:
                existing?.componentPassingMarks.isNotEmpty == true
                ? _ComponentPassingMode.componentWise
                : _ComponentPassingMode.combined,
          ),
        );
        draft.selected = selected;
      }
    });
  }

  void _setClassSelected(
    ExamConfigurationLoaded data,
    AcademicClassEntity academicClass,
    bool selected,
  ) {
    for (final section in data.sections.where(
      (item) => item.classId == academicClass.id,
    )) {
      _setSectionSelected(data, academicClass, section, selected);
    }
  }

  void _applyCommonMarks() {
    final total = double.tryParse(_commonTotalController.text.trim());
    final passing = double.tryParse(_commonPassingController.text.trim());
    if (total == null || total <= 0) {
      _showMessage('Total marks must be greater than zero.');
      return;
    }
    if (passing == null || passing < 0 || passing > total) {
      _showMessage('Passing marks must be between zero and total marks.');
      return;
    }
    setState(() {
      for (final draft in _drafts.values.where((item) => item.selected)) {
        draft.totalController.text = _marksText(total);
        draft.passingController.text = _marksText(passing);
        _distributeDraftEqually(draft);
      }
    });
  }

  Future<void> _pickDate({
    required DateTime? currentDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final selected = await showManualDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) setState(() => onSelected(selected));
  }

  Future<void> _save(ExamConfigurationLoaded data) async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null || _resultDate == null) {
      _showMessage('Select start, end, and result dates.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _showMessage('End date cannot be before the start date.');
      return;
    }
    if (_resultDate!.isBefore(_endDate!)) {
      _showMessage('Result date cannot be before the end date.');
      return;
    }
    final selected = _drafts.values.where((item) => item.selected).toList();
    if (_selectedSectionIds.isEmpty) {
      _showMessage('Select at least one class and section.');
      return;
    }
    if (selected.isEmpty) {
      _showMessage('Select at least one subject.');
      return;
    }
    for (final draft in selected) {
      final total = double.tryParse(draft.totalController.text.trim());
      final passing = double.tryParse(draft.passingController.text.trim());
      if (total == null ||
          total <= 0 ||
          passing == null ||
          passing < 0 ||
          passing > total) {
        _showMessage(
          'Check total and passing marks for ${draft.subject.name}.',
        );
        return;
      }

      if (draft.components.isNotEmpty) {
        var componentTotal = 0.0;

        for (final component in draft.components) {
          final componentMaximum = double.tryParse(
            draft.componentTotalControllers[component.id]!.text.trim(),
          );

          if (componentMaximum == null || componentMaximum <= 0) {
            _showMessage(
              'Check total marks for ${draft.subject.name} '
              '${component.componentName}.',
            );
            return;
          }

          if (draft.componentPassingMode ==
              _ComponentPassingMode.componentWise) {
            final componentPass = double.tryParse(
              draft.componentPassingControllers[component.id]!.text.trim(),
            );

            if (componentPass == null ||
                componentPass < 0 ||
                componentPass > componentMaximum) {
              _showMessage(
                'Enter valid passing marks for ${draft.subject.name} '
                '${component.componentName}.',
              );
              return;
            }
          }

          componentTotal += componentMaximum;
        }

        if ((componentTotal - total).abs() > 0.001) {
          _showMessage(
            '${draft.subject.name} component totals must equal '
            '${_marksText(total)}. Current total: '
            '${_marksText(componentTotal)}.',
          );
          return;
        }
      }
    }

    final existing = widget.exam;
    final now = DateTime.now();
    final exam = ExamEntity(
      id: existing?.id ?? sl<GenerateExamId>()(),
      name: _nameController.text.trim(),
      type: _type,
      academicSession: _sessionController.text.trim(),
      academicYearId: existing?.academicYearId ?? '',
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      startDate: _startDate,
      endDate: _endDate,
      resultDate: _resultDate,
      description: _descriptionController.text.trim(),
      status: _status,
      createdBy: existing?.createdBy ?? '',
    );
    final repository = sl<ExamSubjectSetupRepository>();
    final setups = <ExamSubjectSetupEntity>[];
    for (var index = 0; index < selected.length; index++) {
      final draft = selected[index];
      final old = draft.existing;
      setups.add(
        ExamSubjectSetupEntity(
          id: old?.id ?? repository.generateId(),
          examId: exam.id,
          examName: exam.name,
          academicSession: exam.academicSession,
          academicYearId: exam.academicYearId,
          classId: old?.classId ?? draft.academicClass.id,
          className: draft.academicClass.name,
          sectionId: old?.sectionId ?? draft.section.id,
          sectionName: draft.section.name,
          subjectId: old?.subjectId ?? draft.subject.id,
          subjectName: draft.subject.name,
          totalMarks: double.parse(draft.totalController.text.trim()),
          passingMarks: double.parse(draft.passingController.text.trim()),
          componentTotalMarks: {
            for (final component in draft.components)
              component.id: double.parse(
                draft.componentTotalControllers[component.id]!.text.trim(),
              ),
          },
          componentPassingMarks:
              draft.componentPassingMode == _ComponentPassingMode.componentWise
              ? {
                  for (final component in draft.components)
                    component.id: double.parse(
                      draft.componentPassingControllers[component.id]!.text
                          .trim(),
                    ),
                }
              : const {},
          isActive: true,
          displayOrder: index,
          createdAt: old?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }
    setState(() => _isSaving = true);
    final bloc = context.read<ExamSubjectSetupBloc>();
    final completion = bloc.stream.firstWhere(
      (state) =>
          state is ExamConfigurationSaved || state is ExamSubjectSetupError,
    );
    bloc.add(
      SaveExamConfiguration(exam: exam, setups: setups, isEditing: _isEditing),
    );
    final result = await completion;
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result is ExamSubjectSetupError) {
      _showMessage(result.message);
      context.read<ExamSubjectSetupBloc>().add(
        LoadExamConfiguration(widget.exam),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Exam' : 'Add Exam'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocBuilder<ExamSubjectSetupBloc, ExamSubjectSetupState>(
        builder: (context, state) {
          if (state is ExamConfigurationLoading ||
              state is ExamSubjectSetupInitial ||
              state is ExamConfigurationSaved) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExamSubjectSetupError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<ExamSubjectSetupBloc>().add(
                      LoadExamConfiguration(widget.exam),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final data = state as ExamConfigurationLoaded;
          if (_componentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          _initializeConfiguration(data);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _masterCard(),
                const SizedBox(height: 16),
                _configurationCard(data),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : () => _save(data),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : _isEditing
                          ? 'Save Changes'
                          : 'Create Exam',
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

  Widget _masterCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Examination Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _field(
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Exam Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: _required,
                  ),
                ),
                _field(
                  TextFormField(
                    controller: _sessionController,
                    decoration: const InputDecoration(
                      labelText: 'Academic Session',
                      border: OutlineInputBorder(),
                    ),
                    validator: _required,
                  ),
                ),
                _field(
                  DropdownButtonFormField<ExamType>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Exam Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ExamType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_examTypeLabel(item)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _type = value);
                    },
                  ),
                ),
                _field(
                  DropdownButtonFormField<ExamWorkflowStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Workflow Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ExamWorkflowStatus.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_examStatusLabel(item)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                ),
                _field(
                  _DateSelector(
                    label: 'Start Date',
                    date: _startDate,
                    onPressed: () => _pickDate(
                      currentDate: _startDate,
                      onSelected: (value) => _startDate = value,
                    ),
                  ),
                ),
                _field(
                  _DateSelector(
                    label: 'End Date',
                    date: _endDate,
                    onPressed: () => _pickDate(
                      currentDate: _endDate ?? _startDate,
                      onSelected: (value) => _endDate = value,
                    ),
                  ),
                ),
                _field(
                  _DateSelector(
                    label: 'Result Date',
                    date: _resultDate,
                    onPressed: () => _pickDate(
                      currentDate: _resultDate ?? _endDate,
                      onSelected: (value) => _resultDate = value,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _configurationCard(ExamConfigurationLoaded data) {
    final classes = [...data.classes]..sort((a, b) => a.name.compareTo(b.name));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Classes, Sections and Subjects',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Active subjects are selected automatically when you select a section.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 170,
                  child: TextFormField(
                    controller: _commonTotalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Marks',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: TextFormField(
                    controller: _commonPassingController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Passing Marks',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _applyCommonMarks,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Apply to All Selected Subjects'),
                ),
              ],
            ),
            const Divider(height: 32),
            if (classes.isEmpty) const Text('No active classes found.'),
            ...classes.map((academicClass) => _classPanel(data, academicClass)),
          ],
        ),
      ),
    );
  }

  Widget _classPanel(
    ExamConfigurationLoaded data,
    AcademicClassEntity academicClass,
  ) {
    final sections =
        data.sections.where((item) => item.classId == academicClass.id).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final allSelected =
        sections.isNotEmpty &&
        sections.every((item) => _selectedSectionIds.contains(item.id));
    return ExpansionTile(
      initiallyExpanded: sections.any(
        (item) => _selectedSectionIds.contains(item.id),
      ),
      leading: Checkbox(
        value: allSelected,
        onChanged: (value) =>
            _setClassSelected(data, academicClass, value ?? false),
      ),
      title: Text(academicClass.name),
      subtitle: Text('${sections.length} section(s)'),
      children: sections
          .map((section) => _sectionPanel(data, academicClass, section))
          .toList(),
    );
  }

  Widget _sectionPanel(
    ExamConfigurationLoaded data,
    AcademicClassEntity academicClass,
    SectionEntity section,
  ) {
    final selected = _selectedSectionIds.contains(section.id);
    final subjects = _subjectsFor(data, section)
      ..sort((a, b) => a.name.compareTo(b.name));
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 12),
      child: Column(
        children: [
          CheckboxListTile(
            value: selected,
            title: Text('Section ${section.name}'),
            subtitle: Text('${subjects.length} active subject(s)'),
            onChanged: (value) => _setSectionSelected(
              data,
              academicClass,
              section,
              value ?? false,
            ),
          ),
          if (selected)
            ...subjects.map(
              (subject) => _subjectRow(data, academicClass, section, subject),
            ),
        ],
      ),
    );
  }

  Widget _subjectRow(
    ExamConfigurationLoaded data,
    AcademicClassEntity academicClass,
    SectionEntity section,
    AcademicSubjectEntity subject,
  ) {
    final key = _key(
      widget.exam?.id ?? '',
      academicClass.id,
      section.id,
      subject.id,
    );
    var draft = _drafts[key];
    if (draft == null) {
      final old = data.existingSetups
          .where(
            (item) =>
                (item.classId == academicClass.id ||
                    item.className.toLowerCase() ==
                        academicClass.name.toLowerCase()) &&
                (item.sectionId == section.id ||
                    item.sectionName.toLowerCase() ==
                        section.name.toLowerCase()) &&
                (item.subjectId == subject.id ||
                    item.subjectName.toLowerCase() ==
                        subject.name.toLowerCase()),
          )
          .firstOrNull;
      draft = _SubjectDraft(
        academicClass: academicClass,
        section: section,
        subject: subject,
        selected: true,
        totalMarks: old?.totalMarks ?? 100,
        passingMarks: old?.passingMarks ?? 33,
        existing: old,
        components: _componentsFor(subject),
        componentTotalMarks: old?.componentTotalMarks ?? const {},
        componentPassingMarks: old?.componentPassingMarks ?? const {},
        componentPassingMode: old?.componentPassingMarks.isNotEmpty == true
            ? _ComponentPassingMode.componentWise
            : _ComponentPassingMode.combined,
      );
      _drafts[key] = draft;
    }
    final isProtected =
        draft.existing != null &&
        data.protectedSetupKeys.contains(draft.existing!.uniqueKey);
    final components = draft.components;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: draft.selected,
                onChanged: (value) =>
                    setState(() => draft!.selected = value ?? false),
              ),
              Expanded(child: Text(subject.name)),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: draft.totalController,
                  enabled: draft.selected,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (components.isNotEmpty) setState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: 'Total',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: draft.passingController,
                  enabled: draft.selected,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (components.isNotEmpty) setState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: 'Passing',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              if (components.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: OutlinedButton.icon(
                    onPressed: draft.selected
                        ? () => setState(() => _distributeDraftEqually(draft!))
                        : null,
                    icon: const Icon(Icons.balance_outlined),
                    label: const Text('Equal Split'),
                  ),
                ),
              if (isProtected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Tooltip(
                    message:
                        'Marks already exist; this subject cannot be deselected.',
                    child: Icon(Icons.lock_outline),
                  ),
                ),
            ],
          ),
          if (draft.selected && components.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 48, top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Passing Method',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  RadioGroup<_ComponentPassingMode>(
                    groupValue: draft.componentPassingMode,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => draft!.componentPassingMode = value);
                    },
                    child: Column(
                      children: [
                        RadioListTile<_ComponentPassingMode>(
                          value: _ComponentPassingMode.combined,
                          title: const Text('Combined Subject Passing'),
                          subtitle: Text(
                            'All component marks are added and compared with '
                            '${subject.name} passing marks.',
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<_ComponentPassingMode>(
                          value: _ComponentPassingMode.componentWise,
                          title: const Text('Every Component Must Pass'),
                          subtitle: const Text(
                            'Separate passing marks are required for every '
                            'component.',
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20),
                  for (final component in components)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${subject.name} ${component.componentName}',
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller:
                                  draft.componentTotalControllers[component.id],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Total',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          if (draft.componentPassingMode ==
                              _ComponentPassingMode.componentWise) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 120,
                              child: TextFormField(
                                controller: draft
                                    .componentPassingControllers[component.id],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Passing',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(Widget child) => SizedBox(width: 260, child: child);
  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
}

class _SubjectDraft {
  _SubjectDraft({
    required this.academicClass,
    required this.section,
    required this.subject,
    required this.selected,
    required double totalMarks,
    required double passingMarks,
    required this.components,
    required Map<String, double> componentTotalMarks,
    required Map<String, double> componentPassingMarks,
    required this.componentPassingMode,
    this.existing,
  }) : totalController = TextEditingController(text: _marksText(totalMarks)),
       passingController = TextEditingController(
         text: _marksText(passingMarks),
       ),
       componentTotalControllers = {
         for (final component in components)
           component.id: TextEditingController(
             text: _marksText(
               componentTotalMarks[component.id] ??
                   totalMarks / components.length,
             ),
           ),
       },
       componentPassingControllers = {
         for (final component in components)
           component.id: TextEditingController(
             text: componentPassingMarks.containsKey(component.id)
                 ? _marksText(componentPassingMarks[component.id]!)
                 : '',
           ),
       };

  final AcademicClassEntity academicClass;
  final SectionEntity section;
  final AcademicSubjectEntity subject;
  final ExamSubjectSetupEntity? existing;
  final List<SubjectComponentEntity> components;
  final TextEditingController totalController;
  final TextEditingController passingController;
  final Map<String, TextEditingController> componentTotalControllers;
  final Map<String, TextEditingController> componentPassingControllers;
  _ComponentPassingMode componentPassingMode;
  bool selected;

  void dispose() {
    totalController.dispose();
    passingController.dispose();
    for (final controller in componentTotalControllers.values) {
      controller.dispose();
    }
    for (final controller in componentPassingControllers.values) {
      controller.dispose();
    }
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.label,
    required this.date,
    required this.onPressed,
  });
  final String label;
  final DateTime? date;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.calendar_month_outlined),
    label: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '$label\n${date == null ? 'Select date' : MaterialLocalizations.of(context).formatMediumDate(date!)}',
      ),
    ),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(58),
      alignment: Alignment.centerLeft,
    ),
  );
}

String _marksText(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
String _examTypeLabel(ExamType type) => switch (type) {
  ExamType.monthly => 'Monthly Test',
  ExamType.quarterly => 'Quarterly Test',
  ExamType.midTerm => 'Mid Term',
  ExamType.finalExam => 'Final Term',
};
String _examStatusLabel(ExamWorkflowStatus status) => switch (status) {
  ExamWorkflowStatus.draft => 'Draft',
  ExamWorkflowStatus.active => 'Active',
  ExamWorkflowStatus.completed => 'Completed',
  ExamWorkflowStatus.archived => 'Archived',
};
