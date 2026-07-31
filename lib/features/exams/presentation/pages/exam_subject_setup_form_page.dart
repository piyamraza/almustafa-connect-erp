import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/exam_subject_setup_entity.dart';
import '../../domain/usecases/generate_exam_subject_setup_id.dart';
import '../bloc/exam_subject_setup_bloc.dart';
import '../bloc/exam_subject_setup_event.dart';
import '../bloc/exam_subject_setup_state.dart';

class ExamSubjectSetupFormPage extends StatefulWidget {
  const ExamSubjectSetupFormPage({
    super.key,
    required this.options,
    this.setup,
  });

  final ExamSubjectSetupLoaded options;
  final ExamSubjectSetupEntity? setup;

  @override
  State<ExamSubjectSetupFormPage> createState() =>
      _ExamSubjectSetupFormPageState();
}

class _ExamSubjectSetupFormPageState
    extends State<ExamSubjectSetupFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController(text: '100');
  final _passingController = TextEditingController(text: '33');
  final List<ExamSubjectSetupEntity> _draft = [];

  String? _examId;
  String? _classId;
  String? _sectionId;
  String? _subject;
  bool _isActive = true;
  bool _saving = false;

  bool get _editing => widget.setup != null;

  @override
  void initState() {
    super.initState();
    final setup = widget.setup;
    if (setup == null) return;
    _examId = setup.examId;
    _classId = setup.classId;
    _sectionId = setup.sectionId;
    _subject = setup.subjectName;
    _totalController.text = setup.totalMarks.toString();
    _passingController.text = setup.passingMarks.toString();
    _isActive = setup.isActive;
  }

  @override
  void dispose() {
    _totalController.dispose();
    _passingController.dispose();
    super.dispose();
  }

  String _subjectId(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '_').toLowerCase();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  ExamSubjectSetupEntity? _buildSetup() {
    if (!_formKey.currentState!.validate()) return null;
    final exam = widget.options.exams.firstWhere((value) => value.id == _examId);
    final current = widget.setup;
    final now = DateTime.now();
    return ExamSubjectSetupEntity(
      id: current?.id ?? sl<GenerateExamSubjectSetupId>()(),
      examId: exam.id,
      examName: exam.name,
      academicSession: exam.academicSession,
      classId: _classId!,
      className: _classId!,
      sectionId: _sectionId!,
      sectionName: _sectionId!,
      subjectId: _subjectId(_subject!),
      subjectName: _subject!,
      totalMarks: double.parse(_totalController.text),
      passingMarks: double.parse(_passingController.text),
      isActive: _isActive,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );
  }

  void _addToDraft() {
    final setup = _buildSetup();
    if (setup == null) return;
    if (_draft.any((value) => value.uniqueKey == setup.uniqueKey)) {
      _showMessage('This subject is already in the list.');
      return;
    }
    setState(() {
      _draft.add(setup);
      _subject = null;
    });
  }

  Future<void> _save() async {
    if (_editing) {
      final setup = _buildSetup();
      if (setup != null) await _dispatch(UpdateExamSubjectSetupEvent(setup));
      return;
    }
    if (_draft.isEmpty) _addToDraft();
    if (_draft.isNotEmpty) await _dispatch(CreateExamSubjectSetups(_draft));
  }

  Future<void> _dispatch(ExamSubjectSetupEvent event) async {
    setState(() => _saving = true);
    final bloc = context.read<ExamSubjectSetupBloc>();
    final completed = bloc.stream.firstWhere(
      (state) => state is ExamSubjectSetupLoaded || state is ExamSubjectSetupError,
    );
    bloc.add(event);
    final result = await completed;
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is ExamSubjectSetupError) {
      _showMessage(result.message);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _classId == null
        ? const <String>[]
        : widget.options.sectionsFor(_classId!);
    final subjects = _classId == null || _sectionId == null
        ? const <String>[]
        : widget.options.subjectsFor(_classId!, _sectionId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit Subject Setup' : 'Add Subject Setups'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Form(
              key: _formKey,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _SetupSelect(
                            label: 'Exam',
                            value: _examId,
                            items: widget.options.exams
                                .map((value) => _Choice(value.id, value.name))
                                .toList(),
                            onChanged: (value) => setState(() => _examId = value),
                          ),
                          _SetupSelect(
                            label: 'Class',
                            value: _classId,
                            items: widget.options.classes
                                .map((value) => _Choice(value, value))
                                .toList(),
                            onChanged: (value) => setState(() {
                              _classId = value;
                              _sectionId = null;
                              _subject = null;
                            }),
                          ),
                          _SetupSelect(
                            label: 'Section',
                            value: _sectionId,
                            items: sections.map((value) => _Choice(value, value)).toList(),
                            onChanged: (value) => setState(() {
                              _sectionId = value;
                              _subject = null;
                            }),
                          ),
                          _SetupSelect(
                            label: 'Subject',
                            value: _subject,
                            items: subjects.map((value) => _Choice(value, value)).toList(),
                            onChanged: (value) => setState(() => _subject = value),
                          ),
                          SizedBox(
                            width: 190,
                            child: TextFormField(
                              controller: _totalController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Total Marks',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final marks = double.tryParse(value ?? '');
                                return marks == null || marks <= 0
                                    ? 'Enter total marks greater than zero.'
                                    : null;
                              },
                            ),
                          ),
                          SizedBox(
                            width: 190,
                            child: TextFormField(
                              controller: _passingController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Passing Marks',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final passing = double.tryParse(value ?? '');
                                final total = double.tryParse(_totalController.text);
                                return passing == null ||
                                        passing < 0 ||
                                        total == null ||
                                        passing > total
                                    ? 'Passing marks must be within total marks.'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                      if (!_editing)
                        OutlinedButton.icon(
                          onPressed: _addToDraft,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Subject to List'),
                        ),
                      if (_draft.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Pending Configurations (${_draft.length})'),
                        ..._draft.map(
                          (setup) => ListTile(
                            title: Text(setup.subjectName),
                            subtitle: Text(
                              'Total ${setup.totalMarks} • Passing ${setup.passingMarks}',
                            ),
                            trailing: IconButton(
                              onPressed: () => setState(() => _draft.remove(setup)),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.save),
                          label: Text(
                            _saving
                                ? 'Saving...'
                                : _editing
                                    ? 'Save Changes'
                                    : 'Save Configurations',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Choice {
  const _Choice(this.id, this.name);
  final String id;
  final String name;
}

class _SetupSelect extends StatelessWidget {
  const _SetupSelect({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<_Choice> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: DropdownButtonFormField<String>(
        initialValue: items.any((item) => item.id == value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item.id,
                child: Text(item.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? '$label is required.' : null,
      ),
    );
  }
}
