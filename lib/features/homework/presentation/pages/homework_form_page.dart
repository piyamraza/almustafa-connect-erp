import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/manual_date_picker.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../../core/di/service_locator.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../../academic_calendar/domain/services/academic_calendar_policy_service.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../teachers/domain/repositories/teacher_assignment_repository.dart';
import '../../domain/entities/homework_entity.dart';
import '../../domain/repositories/homework_repository.dart';
import '../../domain/services/homework_attachment_service.dart';

class HomeworkFormPage extends StatefulWidget {
  const HomeworkFormPage({
    super.key,
    required this.academicSession,
    this.existing,
    this.copyFrom,
    this.initialClassId,
    this.initialSectionId,
    this.initialSubjectId,
    this.initialAssignedDate,
    this.lockedTeacherId,
  });

  final String academicSession;
  final HomeworkEntity? existing;
  final HomeworkEntity? copyFrom;
  final String? initialClassId;
  final String? initialSectionId;
  final String? initialSubjectId;
  final DateTime? initialAssignedDate;
  final String? lockedTeacherId;

  @override
  State<HomeworkFormPage> createState() => _HomeworkFormPageState();
}

class _HomeworkFormPageState extends State<HomeworkFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _instructions;
  List<dynamic> _classes = [];
  List<dynamic> _sections = [];
  List<dynamic> _subjects = [];
  List<dynamic> _assignments = [];
  final List<HomeworkAttachmentEntity> _attachments = [];
  String? _classId;
  String? _sectionId;
  String? _subjectId;
  String? _teacherId;
  DateTime _assigned = DateTime.now();
  DateTime _due = DateTime.now().add(const Duration(days: 1));
  HomeworkStatus _status = HomeworkStatus.draft;
  bool _loading = true;
  bool _uploading = false;
  bool _saving = false;
  late final String _homeworkId;

  HomeworkEntity? get _source => widget.existing ?? widget.copyFrom;

  @override
  void initState() {
    super.initState();
    final source = _source;
    _homeworkId = widget.existing?.id ?? sl<HomeworkRepository>().generateId();
    _title = TextEditingController(text: source?.title ?? '');
    _description = TextEditingController(text: source?.description ?? '');
    _instructions = TextEditingController(text: source?.instructions ?? '');
    _classId = source?.classId ?? widget.initialClassId;
    _sectionId = source?.sectionId ?? widget.initialSectionId;
    _subjectId = source?.subjectId ?? widget.initialSubjectId;
    _teacherId = source?.teacherId ?? widget.lockedTeacherId;
    _assigned = widget.copyFrom == null
        ? source?.assignedDate ?? widget.initialAssignedDate ?? DateTime.now()
        : DateTime.now();
    _due = widget.copyFrom == null
        ? source?.dueDate ??
              (widget.initialAssignedDate ?? DateTime.now()).add(
                const Duration(days: 1),
              )
        : DateTime.now().add(const Duration(days: 1));
    _status = widget.existing?.status ?? HomeworkStatus.draft;
    _attachments.addAll(source?.attachments ?? const []);
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<Object?>([
        sl<AcademicStructureRepository>().getClasses(),
        sl<AcademicStructureRepository>().getSections(),
        sl<AcademicStructureRepository>().getSubjects(),
        sl<TeacherAssignmentRepository>().getAssignments(),
      ]);
      if (!mounted) return;
      setState(() {
        _classes = values[0] as List<dynamic>;
        _sections = values[1] as List<dynamic>;
        _subjects = values[2] as List<dynamic>;
        _assignments = (values[3] as List<dynamic>)
            .where(
              (item) =>
                  widget.lockedTeacherId == null ||
                  item.teacherId.toString() == widget.lockedTeacherId,
            )
            .toList();
        _teacherId ??= widget.lockedTeacherId;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(error.toString());
    }
  }

  List<dynamic> get _validSections =>
      _sections.where((e) => e.classId == _classId).toList();

  List<dynamic> get _validSubjects => _subjects
      .where(
        (e) =>
            e.classId == _classId &&
            (e.sectionId == null || e.sectionId == _sectionId),
      )
      .toList();

  String _name(List<dynamic> values, String? id) {
    for (final value in values) {
      if (value.id.toString() == id) return value.name.toString();
    }
    return '';
  }

  List<dynamic> get _validTeachers => _assignments.where((e) {
    final className = _name(_classes, _classId);
    final sectionName = _name(_sections, _sectionId);
    final subjectName = _name(_subjects, _subjectId);
    return e.academicSession.toString().trim() ==
            widget.academicSession.trim() &&
        (e.classId.toString() == _classId ||
            e.classId.toString() == className) &&
        (e.sectionId.toString() == _sectionId ||
            e.sectionId.toString() == sectionName) &&
        e.subject.toString().trim().toLowerCase() ==
            subjectName.trim().toLowerCase();
  }).toList();

  String _teacherName() {
    for (final e in _assignments) {
      if (e.teacherId.toString() == _teacherId) {
        return e.teacherName.toString();
      }
    }
    return '';
  }

  Future<void> _pickDate(bool assigned) async {
    final value = await showManualDatePicker(
      context: context,
      initialDate: assigned ? _assigned : _due,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value == null) return;
    setState(() {
      if (assigned) {
        _assigned = value;
        if (_due.isBefore(value)) _due = value;
      } else {
        _due = value;
      }
    });
  }

  Future<void> _upload() async {
    setState(() => _uploading = true);
    try {
      final values = await sl<HomeworkAttachmentService>().pickAndUpload(
        homeworkId: _homeworkId,
      );
      if (!mounted) return;
      setState(() => _attachments.addAll(values));
    } catch (error) {
      _snack(error.toString().replaceFirst('StateError: ', ''));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeAttachment(HomeworkAttachmentEntity attachment) async {
    try {
      await sl<HomeworkAttachmentService>().deleteAttachment(attachment);
      if (mounted) {
        setState(() => _attachments.remove(attachment));
      }
    } catch (error) {
      _snack(error.toString());
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) {
      _snack('Please complete all required fields.');
      return;
    }

    if ([_classId, _sectionId, _subjectId, _teacherId].contains(null)) {
      _snack('Class, section, subject and teacher are required.');
      return;
    }
    if (widget.lockedTeacherId != null &&
        _teacherId != widget.lockedTeacherId) {
      _snack('You can only save homework for your own assigned subject.');
      return;
    }

    setState(() => _saving = true);

    try {
      final calendar = await sl<AcademicCalendarPolicyService>()
          .validateHomeworkDueDate(
            academicSession: widget.academicSession,
            date: _due,
          );

      if (!mounted) return;

      if (!calendar.allowed) {
        if (calendar.suggestedDate == null) {
          _snack(calendar.message);
          return;
        }

        final useSuggested =
            await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Invalid Due Date'),
                content: Text(
                  '${calendar.message}\n\n'
                  'Suggested: ${_date(calendar.suggestedDate!)}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Use Suggested'),
                  ),
                ],
              ),
            ) ??
            false;

        if (!useSuggested) return;
        _due = calendar.suggestedDate!;
      }

      final now = DateTime.now();
      final old = widget.existing;
      final actor = sl<AccessControlService>().currentUserEmail ?? 'Admin';

      final homework = HomeworkEntity(
        id: _homeworkId,
        academicSession: widget.academicSession,
        classId: _classId!,
        className: _name(_classes, _classId),
        sectionId: _sectionId!,
        sectionName: _name(_sections, _sectionId),
        subjectId: _subjectId!,
        subjectName: _name(_subjects, _subjectId),
        teacherId: _teacherId!,
        teacherName: _teacherName(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        instructions: _instructions.text.trim(),
        assignedDate: _assigned,
        dueDate: _due,
        status: _status,
        attachments: _attachments,
        createdBy: old?.createdBy ?? actor,
        updatedBy: actor,
        publishedBy: _status == HomeworkStatus.published
            ? actor
            : old?.publishedBy,
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
        publishedAt: _status == HomeworkStatus.published
            ? old?.publishedAt ?? now
            : old?.publishedAt,
        sourceHomeworkId: widget.copyFrom?.id ?? old?.sourceHomeworkId,
      );

      final repository = sl<HomeworkRepository>();
      final duplicate = await repository.duplicateExists(homework);

      if (!mounted) return;

      if (duplicate) {
        final proceed =
            await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Possible Duplicate'),
                content: const Text(
                  'Same title, class, section and subject already '
                  'exist for this assigned date. Save anyway?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Save Anyway'),
                  ),
                ],
              ),
            ) ??
            false;

        if (!proceed) return;
      }

      await repository.saveHomework(homework);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint('Homework save failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      _snack(
        'Homework could not be saved: '
        '${error.toString().replaceFirst('StateError: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: Text(
          widget.existing != null
              ? 'Edit Homework'
              : widget.copyFrom != null
              ? 'Copy Homework'
              : 'Create Homework',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _select('Class', _classId, _classes, (value) {
                  setState(() {
                    _classId = value;
                    _sectionId = null;
                    _subjectId = null;
                    _teacherId = widget.lockedTeacherId;
                  });
                }),
                _select('Section', _sectionId, _validSections, (value) {
                  setState(() {
                    _sectionId = value;
                    _subjectId = null;
                    _teacherId = widget.lockedTeacherId;
                  });
                }),
                _select('Subject', _subjectId, _validSubjects, (value) {
                  setState(() {
                    _subjectId = value;
                    _teacherId = widget.lockedTeacherId;
                  });
                }),
                SizedBox(
                  width: 230,
                  child: DropdownButtonFormField<String>(
                    initialValue: _teacherId,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Teacher',
                      border: OutlineInputBorder(),
                    ),
                    items: _validTeachers
                        .map<DropdownMenuItem<String>>(
                          (e) => DropdownMenuItem(
                            value: e.teacherId.toString(),
                            child: Text(e.teacherName.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: widget.lockedTeacherId == null
                        ? (value) => setState(() => _teacherId = value)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Homework Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Title is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructions,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Detailed Instructions',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickDate(true),
                  icon: const Icon(Icons.date_range),
                  label: Text('Assigned: ${_date(_assigned)}'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(false),
                  icon: const Icon(Icons.event),
                  label: Text('Due: ${_date(_due)}'),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<HomeworkStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: HomeworkStatus.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _status = value ?? _status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Attachments (PDF, Office, Images, ZIP — max 15 MB each)',
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _uploading ? null : _upload,
                          icon: _uploading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file),
                          label: const Text('Select & Upload'),
                        ),
                      ],
                    ),
                    for (final attachment in _attachments)
                      ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text(attachment.fileName),
                        subtitle: Text(
                          '${attachment.fileType.toUpperCase()} • '
                          '${(attachment.fileSize / 1024).toStringAsFixed(1)} KB',
                        ),
                        trailing: IconButton(
                          onPressed: () => _removeAttachment(attachment),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Homework'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _select(
    String label,
    String? value,
    List<dynamic> items,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map<DropdownMenuItem<String>>(
              (e) => DropdownMenuItem(
                value: e.id.toString(),
                child: Text(e.name.toString()),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
