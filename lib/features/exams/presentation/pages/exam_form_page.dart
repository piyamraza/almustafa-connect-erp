import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/usecases/generate_exam_id.dart';
import '../bloc/exam_bloc.dart';
import '../bloc/exam_event.dart';
import '../bloc/exam_state.dart';

class ExamFormPage extends StatefulWidget {
  const ExamFormPage({super.key, this.exam});

  final ExamEntity? exam;

  @override
  State<ExamFormPage> createState() => _ExamFormPageState();
}

class _ExamFormPageState extends State<ExamFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _sessionController;
  late final TextEditingController _descriptionController;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _resultDate;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    final exam = widget.exam;
    _nameController = TextEditingController(text: exam?.name ?? '');
    _sessionController = TextEditingController(text: exam?.academicSession ?? '');
    _descriptionController = TextEditingController(text: exam?.description ?? '');
    _startDate = exam?.startDate ?? exam?.examDate;
    _endDate = exam?.endDate ?? exam?.examDate;
    _resultDate = exam?.resultDate ?? exam?.examDate;
    _isActive = exam?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sessionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? currentDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) {
      setState(() => onSelected(selected));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
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

    setState(() => _isSaving = true);
    final existing = widget.exam;
    final exam = ExamEntity(
      id: existing?.id ?? sl<GenerateExamId>()(),
      name: _nameController.text.trim(),
      type: existing?.type ?? ExamType.monthly,
      academicSession: _sessionController.text.trim(),
      classId: existing?.classId ?? '',
      sectionId: existing?.sectionId ?? '',
      subject: existing?.subject ?? '',
      examDate: _startDate!,
      totalMarks: existing?.totalMarks ?? 0,
      passingMarks: existing?.passingMarks ?? 0,
      createdAt: existing?.createdAt ?? DateTime.now(),
      startDate: _startDate,
      endDate: _endDate,
      resultDate: _resultDate,
      description: _descriptionController.text.trim(),
      isActive: _isActive,
    );

    final bloc = context.read<ExamBloc>();
    final completion = bloc.stream.firstWhere(
      (state) => state is ExamLoaded || state is ExamError,
    );
    bloc.add(_isEditing ? UpdateExam(exam) : CreateExam(exam));
    final state = await completion;

    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    if (state is ExamError) {
      _showMessage(state.message);
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Edit Exam' : 'Add Exam';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Form(
                  key: _formKey,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing
                                ? 'Update examination information'
                                : 'Create a new examination schedule',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 24),
                          _ResponsiveFields(
                            wide: constraints.maxWidth >= 700,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Exam Name',
                                  prefixIcon: Icon(Icons.assignment_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) => value == null ||
                                        value.trim().isEmpty
                                    ? 'Exam name is required.'
                                    : null,
                              ),
                              TextFormField(
                                controller: _sessionController,
                                decoration: const InputDecoration(
                                  labelText: 'Academic Session',
                                  hintText: 'e.g. 2026-2027',
                                  prefixIcon: Icon(Icons.calendar_today_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) => value == null ||
                                        value.trim().isEmpty
                                    ? 'Academic session is required.'
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _ResponsiveFields(
                            wide: constraints.maxWidth >= 700,
                            children: [
                              _DateSelector(
                                label: 'Start Date',
                                date: _startDate,
                                onPressed: () => _pickDate(
                                  currentDate: _startDate,
                                  onSelected: (value) => _startDate = value,
                                ),
                              ),
                              _DateSelector(
                                label: 'End Date',
                                date: _endDate,
                                onPressed: () => _pickDate(
                                  currentDate: _endDate ?? _startDate,
                                  onSelected: (value) => _endDate = value,
                                ),
                              ),
                              _DateSelector(
                                label: 'Result Date',
                                date: _resultDate,
                                onPressed: () => _pickDate(
                                  currentDate: _resultDate ?? _endDate,
                                  onSelected: (value) => _resultDate = value,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _descriptionController,
                            minLines: 3,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Exam Status'),
                            subtitle: Text(_isActive ? 'Active' : 'Inactive'),
                            value: _isActive,
                            onChanged: (value) => setState(() => _isActive = value),
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton.icon(
                                  onPressed: _isSaving ? null : _save,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(_isSaving
                                      ? 'Saving...'
                                      : _isEditing
                                          ? 'Save Changes'
                                          : 'Create Exam'),
                                ),
                              ],
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
        ),
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.wide, required this.children});

  final bool wide;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final child in children) SizedBox(width: 260, child: child),
      ],
    );
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
  Widget build(BuildContext context) {
    final dateText = date == null
        ? 'Select date'
        : MaterialLocalizations.of(context).formatMediumDate(date!);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_month_outlined),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text('$label\n$dateText'),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
