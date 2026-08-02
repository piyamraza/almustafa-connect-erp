[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = (Get-Location).Path
$pubspec = Join-Path $projectRoot 'pubspec.yaml'

if (-not (Test-Path -LiteralPath $pubspec)) {
    throw 'Run this installer from the Almustafa Connect ERP project root.'
}

$files = @(
    'lib/features/exams/domain/entities/exam_entity.dart',
    'lib/features/exams/data/models/exam_model.dart',
    'lib/features/exams/presentation/pages/exam_form_page.dart',
    'lib/features/exams/presentation/pages/exams_page.dart'
)

foreach ($relativePath in $files) {
    $absolutePath = Join-Path $projectRoot $relativePath
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Required file not found: $relativePath"
    }
}

$anchors = @{
    'lib/features/exams/domain/entities/exam_entity.dart' = 'required this.classId'
    'lib/features/exams/data/models/exam_model.dart' = "classId: map['classId']"
    'lib/features/exams/presentation/pages/exam_form_page.dart' = 'classId: existing?.classId'
    'lib/features/exams/presentation/pages/exams_page.dart' = 'class _ExamStatusChip extends StatelessWidget'
}

foreach ($entry in $anchors.GetEnumerator()) {
    $absolutePath = Join-Path $projectRoot $entry.Key
    $content = [IO.File]::ReadAllText($absolutePath)
    if (-not $content.Contains($entry.Value)) {
        throw "ANCHOR ERROR: '$($entry.Value)' was not found in $($entry.Key). No files were changed."
    }
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path `
    (Split-Path $projectRoot -Parent) `
    "almustafa-connect-erp_backups\examination_master_structure_$stamp"

foreach ($relativePath in $files) {
    $source = Join-Path $projectRoot $relativePath
    $destination = Join-Path $backupRoot $relativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
}

$utf8 = New-Object System.Text.UTF8Encoding($false)

$examEntity = @'
import 'package:equatable/equatable.dart';

enum ExamType { monthly, quarterly, midTerm, finalExam }

enum ExamWorkflowStatus { draft, active, completed, archived }

/// Master examination configuration.
///
/// Class, section, subject, individual paper date and marks criteria belong to
/// exam subject setup and date-sheet records. Legacy fields remain temporarily
/// for backward-compatible reads during the staged migration.
class ExamEntity extends Equatable {
  const ExamEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.academicSession,
    required this.createdAt,
    this.academicYearId = '',
    this.startDate,
    this.endDate,
    this.resultDate,
    this.description = '',
    ExamWorkflowStatus? status,
    bool? isActive,
    this.createdBy = '',
    this.updatedAt,
    this.classId = '',
    this.sectionId = '',
    this.subject = '',
    DateTime? examDate,
    this.totalMarks = 0,
    this.passingMarks = 0,
  })  : status = status ??
            ((isActive ?? true)
                ? ExamWorkflowStatus.active
                : ExamWorkflowStatus.draft),
        examDate = examDate ?? startDate ?? createdAt;

  final String id;
  final String name;
  final ExamType type;

  /// Human-readable session snapshot, for example 2026-2027.
  final String academicSession;

  /// Stable academic-year reference. It may remain empty for migrated records.
  final String academicYearId;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? resultDate;
  final String description;
  final ExamWorkflowStatus status;
  final String createdBy;

  /// Legacy compatibility fields.
  ///
  /// New writes must keep these empty. Their data belongs to subject setup or
  /// the date sheet and is retained only so older records remain readable.
  final String classId;
  final String sectionId;
  final String subject;
  final DateTime examDate;
  final double totalMarks;
  final double passingMarks;

  bool get isActive => status == ExamWorkflowStatus.active;

  bool get isEditable =>
      status == ExamWorkflowStatus.draft ||
      status == ExamWorkflowStatus.active;

  ExamEntity copyWith({
    String? id,
    String? name,
    ExamType? type,
    String? academicSession,
    String? academicYearId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? resultDate,
    String? description,
    ExamWorkflowStatus? status,
    bool? isActive,
    String? createdBy,
    String? classId,
    String? sectionId,
    String? subject,
    DateTime? examDate,
    double? totalMarks,
    double? passingMarks,
  }) {
    final resolvedStatus = status ??
        (isActive == null
            ? this.status
            : isActive
                ? ExamWorkflowStatus.active
                : ExamWorkflowStatus.draft);

    return ExamEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      academicSession: academicSession ?? this.academicSession,
      academicYearId: academicYearId ?? this.academicYearId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      resultDate: resultDate ?? this.resultDate,
      description: description ?? this.description,
      status: resolvedStatus,
      createdBy: createdBy ?? this.createdBy,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      subject: subject ?? this.subject,
      examDate: examDate ?? this.examDate,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        academicSession,
        academicYearId,
        createdAt,
        updatedAt,
        startDate,
        endDate,
        resultDate,
        description,
        status,
        createdBy,
        classId,
        sectionId,
        subject,
        examDate,
        totalMarks,
        passingMarks,
      ];
}
'@

$examModel = @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/exam_entity.dart';

/// Firestore representation of the examination master record.
class ExamModel extends ExamEntity {
  const ExamModel({
    required super.id,
    required super.name,
    required super.type,
    required super.academicSession,
    required super.createdAt,
    super.academicYearId,
    super.startDate,
    super.endDate,
    super.resultDate,
    super.description,
    super.status,
    super.isActive,
    super.createdBy,
    super.updatedAt,
    super.classId,
    super.sectionId,
    super.subject,
    super.examDate,
    super.totalMarks,
    super.passingMarks,
  });

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    final createdAt = _dateFromValue(map['createdAt']) ?? now;
    final startDate =
        _dateFromValue(map['startDate']) ?? _dateFromValue(map['examDate']);

    return ExamModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: _examTypeFromValue(map['type']),
      academicSession: map['academicSession'] as String? ?? '',
      academicYearId: map['academicYearId'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: _dateFromValue(map['updatedAt']),
      startDate: startDate,
      endDate: _dateFromValue(map['endDate']) ?? startDate,
      resultDate: _dateFromValue(map['resultDate']) ?? startDate,
      description: map['description'] as String? ?? '',
      status: _statusFromMap(map),
      createdBy: map['createdBy'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      examDate: _dateFromValue(map['examDate']) ?? startDate ?? createdAt,
      totalMarks: _doubleFromValue(map['totalMarks']),
      passingMarks: _doubleFromValue(map['passingMarks']),
    );
  }

  factory ExamModel.fromEntity(ExamEntity entity) {
    return ExamModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      academicSession: entity.academicSession,
      academicYearId: entity.academicYearId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      startDate: entity.startDate,
      endDate: entity.endDate,
      resultDate: entity.resultDate,
      description: entity.description,
      status: entity.status,
      createdBy: entity.createdBy,
      classId: entity.classId,
      sectionId: entity.sectionId,
      subject: entity.subject,
      examDate: entity.examDate,
      totalMarks: entity.totalMarks,
      passingMarks: entity.passingMarks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'academicSession': academicSession,
      'academicYearId': academicYearId,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'resultDate': resultDate?.toIso8601String(),
      'description': description,
      'status': status.name,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'schemaVersion': 2,
    };
  }

  static ExamType _examTypeFromValue(dynamic value) {
    final typeName = value as String?;
    return ExamType.values.firstWhere(
      (type) => type.name == typeName,
      orElse: () => ExamType.monthly,
    );
  }

  static ExamWorkflowStatus _statusFromMap(Map<String, dynamic> map) {
    final value = map['status'] as String?;
    if (value != null) {
      return ExamWorkflowStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => ExamWorkflowStatus.draft,
      );
    }

    return (map['isActive'] as bool? ?? true)
        ? ExamWorkflowStatus.active
        : ExamWorkflowStatus.draft;
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double _doubleFromValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
'@

$examFormPage = @'
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
  late ExamType _type;
  late ExamWorkflowStatus _status;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _resultDate;
  bool _isSaving = false;

  bool get _isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    final exam = widget.exam;
    _nameController = TextEditingController(text: exam?.name ?? '');
    _sessionController =
        TextEditingController(text: exam?.academicSession ?? '');
    _descriptionController =
        TextEditingController(text: exam?.description ?? '');
    _type = exam?.type ?? ExamType.monthly;
    _status = exam?.status ?? ExamWorkflowStatus.draft;
    _startDate = exam?.startDate;
    _endDate = exam?.endDate;
    _resultDate = exam?.resultDate;
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

    setState(() => _isSaving = true);
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

    final bloc = context.read<ExamBloc>();
    final completion = bloc.stream.firstWhere(
      (state) => state is ExamLoaded || state is ExamError,
    );
    bloc.add(_isEditing ? UpdateExam(exam) : CreateExam(exam));
    final state = await completion;

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (state is ExamError) {
      _showMessage(state.message);
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
                                ? 'Update examination master information'
                                : 'Create examination master record',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Class, section, subjects, marks and paper dates are configured separately.',
                            style: Theme.of(context).textTheme.bodyMedium,
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
                                  prefixIcon:
                                      Icon(Icons.assignment_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Exam name is required.'
                                        : null,
                              ),
                              TextFormField(
                                controller: _sessionController,
                                decoration: const InputDecoration(
                                  labelText: 'Academic Session',
                                  hintText: 'e.g. 2026-2027',
                                  prefixIcon:
                                      Icon(Icons.calendar_today_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Academic session is required.'
                                        : null,
                              ),
                              DropdownButtonFormField<ExamType>(
                                initialValue: _type,
                                decoration: const InputDecoration(
                                  labelText: 'Exam Type',
                                  prefixIcon: Icon(Icons.category_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                items: ExamType.values
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(_examTypeLabel(type)),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _type = value);
                                  }
                                },
                              ),
                              DropdownButtonFormField<ExamWorkflowStatus>(
                                initialValue: _status,
                                decoration: const InputDecoration(
                                  labelText: 'Workflow Status',
                                  prefixIcon:
                                      Icon(Icons.account_tree_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                items: ExamWorkflowStatus.values
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(
                                          _examStatusLabel(status),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _status = value);
                                  }
                                },
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
                            textCapitalization:
                                TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(),
                            ),
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
                                  label: Text(
                                    _isSaving
                                        ? 'Saving...'
                                        : _isEditing
                                            ? 'Save Changes'
                                            : 'Create Exam',
                                  ),
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
            if (index < children.length - 1)
              const SizedBox(height: 16),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final child in children)
          SizedBox(width: 260, child: child),
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

String _examTypeLabel(ExamType type) {
  return switch (type) {
    ExamType.monthly => 'Monthly Test',
    ExamType.quarterly => 'Quarterly Test',
    ExamType.midTerm => 'Mid Term',
    ExamType.finalExam => 'Final Term',
  };
}

String _examStatusLabel(ExamWorkflowStatus status) {
  return switch (status) {
    ExamWorkflowStatus.draft => 'Draft',
    ExamWorkflowStatus.active => 'Active',
    ExamWorkflowStatus.completed => 'Completed',
    ExamWorkflowStatus.archived => 'Archived',
  };
}
'@

$examsPagePath = Join-Path $projectRoot 'lib/features/exams/presentation/pages/exams_page.dart'
$examsPage = [IO.File]::ReadAllText($examsPagePath).Replace("`r`n", "`n")

$oldDetailStatus = @'
                _DetailRow(
                  label: 'Status',
                  value: exam.isActive ? 'Active' : 'Inactive',
                ),
'@

$newDetailStatus = @'
                _DetailRow(
                  label: 'Type',
                  value: _examTypeLabel(exam.type),
                ),
                _DetailRow(
                  label: 'Status',
                  value: _examStatusLabel(exam.status),
                ),
'@

if (-not $examsPage.Contains($oldDetailStatus)) {
    throw 'ANCHOR ERROR: Exam detail status block was not found. No files were changed.'
}
$examsPage = $examsPage.Replace($oldDetailStatus, $newDetailStatus)

$oldChipCall = '_ExamStatusChip(isActive: exam.isActive)'
$newChipCall = '_ExamStatusChip(status: exam.status)'
if (-not $examsPage.Contains($oldChipCall)) {
    throw 'ANCHOR ERROR: Exam status chip call was not found. No files were changed.'
}
$examsPage = $examsPage.Replace($oldChipCall, $newChipCall)

$oldChipClass = @'
class _ExamStatusChip extends StatelessWidget {
  const _ExamStatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Chip(
      label: Text(isActive ? 'Active' : 'Inactive'),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: isActive
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isActive ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
'@

$newChipClass = @'
class _ExamStatusChip extends StatelessWidget {
  const _ExamStatusChip({required this.status});

  final ExamWorkflowStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isActive = status == ExamWorkflowStatus.active;

    return Chip(
      label: Text(_examStatusLabel(status)),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: isActive
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isActive
            ? colors.onPrimaryContainer
            : colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
'@

if (-not $examsPage.Contains($oldChipClass)) {
    throw 'ANCHOR ERROR: Exam status chip class was not found. No files were changed.'
}
$examsPage = $examsPage.Replace($oldChipClass, $newChipClass)

$helperAnchor = @'
String _formatDate(BuildContext context, DateTime? value) {
'@

$helpers = @'
String _examTypeLabel(ExamType type) {
  return switch (type) {
    ExamType.monthly => 'Monthly Test',
    ExamType.quarterly => 'Quarterly Test',
    ExamType.midTerm => 'Mid Term',
    ExamType.finalExam => 'Final Term',
  };
}

String _examStatusLabel(ExamWorkflowStatus status) {
  return switch (status) {
    ExamWorkflowStatus.draft => 'Draft',
    ExamWorkflowStatus.active => 'Active',
    ExamWorkflowStatus.completed => 'Completed',
    ExamWorkflowStatus.archived => 'Archived',
  };
}

'@

if (-not $examsPage.Contains($helperAnchor)) {
    throw 'ANCHOR ERROR: Date formatter helper anchor was not found. No files were changed.'
}
$examsPage = $examsPage.Replace($helperAnchor, $helpers + $helperAnchor)

[IO.File]::WriteAllText(
    (Join-Path $projectRoot 'lib/features/exams/domain/entities/exam_entity.dart'),
    $examEntity,
    $utf8
)
[IO.File]::WriteAllText(
    (Join-Path $projectRoot 'lib/features/exams/data/models/exam_model.dart'),
    $examModel,
    $utf8
)
[IO.File]::WriteAllText(
    (Join-Path $projectRoot 'lib/features/exams/presentation/pages/exam_form_page.dart'),
    $examFormPage,
    $utf8
)
[IO.File]::WriteAllText($examsPagePath, $examsPage, $utf8)

Write-Host ''
Write-Host 'Running dart format...' -ForegroundColor Cyan

& dart format `
    lib/features/exams/domain/entities/exam_entity.dart `
    lib/features/exams/data/models/exam_model.dart `
    lib/features/exams/presentation/pages/exam_form_page.dart `
    lib/features/exams/presentation/pages/exams_page.dart

if ($LASTEXITCODE -ne 0) {
    throw "dart format failed. Backup is available at: $backupRoot"
}

Write-Host ''
Write-Host 'Running flutter analyze...' -ForegroundColor Cyan

& flutter analyze

if ($LASTEXITCODE -ne 0) {
    throw "flutter analyze found issues. Restore from: $backupRoot"
}

Write-Host ''
Write-Host 'Examination master structure Phase 1 installed successfully.' -ForegroundColor Green
Write-Host 'Exam master now owns identity, type, session, dates and workflow status.' -ForegroundColor Cyan
Write-Host 'Legacy class, section, subject and marks fields remain read-compatible but are no longer written.' -ForegroundColor Cyan
Write-Host "Backup: $backupRoot" -ForegroundColor DarkGray
