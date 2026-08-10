import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../access_control/domain/entities/app_permission.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_class_order.dart';
import '../../domain/entities/syllabus_entry_entity.dart';
import '../../domain/entities/syllabus_plan_entity.dart';
import '../../domain/repositories/syllabus_repository.dart';
import '../services/syllabus_pdf_service.dart';

class SyllabusManagementTab extends StatefulWidget {
  const SyllabusManagementTab({super.key});

  @override
  State<SyllabusManagementTab> createState() => _SyllabusManagementTabState();
}

class _SyllabusManagementTabState extends State<SyllabusManagementTab> {
  final _session = TextEditingController(text: '2026-2027');
  final _title = TextEditingController();
  List<AcademicClassEntity> _classes = const [];
  List<SectionEntity> _sections = const [];
  List<AcademicSubjectEntity> _subjects = const [];
  List<SyllabusEntryEntity> _allEntries = const [];
  List<SyllabusPlanEntity> _plans = const [];
  SyllabusPlanEntity? _editingPlan;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  List<SyllabusEntryEntity> get _entries {
    return _allEntries
        .where((item) => item.planId == _editingPlan?.id)
        .toList();
  }

  bool get _canManage =>
      sl<AccessControlService>().hasPermission(AppPermission.homeworkCreate);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _session.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait<Object>([
        sl<AcademicStructureRepository>().getClasses(),
        sl<AcademicStructureRepository>().getSections(),
        sl<AcademicStructureRepository>().getSubjects(),
        sl<SyllabusRepository>().getEntries(
          academicSession: _session.text.trim(),
        ),
        sl<SyllabusRepository>().getPlans(
          academicSession: _session.text.trim(),
          publishedOnly: !_canManage,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _classes = result[0] as List<AcademicClassEntity>;
        _sections = result[1] as List<SectionEntity>;
        _subjects = result[2] as List<AcademicSubjectEntity>;
        _allEntries = result[3] as List<SyllabusEntryEntity>;
        _plans = result[4] as List<SyllabusPlanEntity>;
        if (_editingPlan != null) {
          _editingPlan = _plans
              .where((item) => item.id == _editingPlan!.id)
              .firstOrNull;
          if (_editingPlan != null) _title.text = _editingPlan!.title;
        }
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: Text('Retry: $_error'),
        ),
      );
    }
    if (_editingPlan == null) return _syllabusList();
    final rows =
        _sections.where((section) {
          return section.isActive && _class(section.classId)?.isActive == true;
        }).toList()..sort((a, b) {
          final byClass = compareAcademicClassNames(
            _class(a.classId)?.name ?? '',
            _class(b.classId)?.name ?? '',
          );
          return byClass != 0 ? byClass : a.name.compareTo(b.name);
        });

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _toolbar(),
            const SizedBox(height: 14),
            for (final section in rows) _classRow(section),
          ],
        ),
        if (_saving) const LinearProgressIndicator(),
      ],
    );
  }

  Widget _syllabusList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Syllabus Management',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _canManage
                        ? 'Create, edit, preview and publish syllabus.'
                        : 'Published syllabus shared by the school.',
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _session,
                decoration: const InputDecoration(
                  labelText: 'Academic Session',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Load session',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
            if (_canManage) ...[
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _createPlan,
                icon: const Icon(Icons.add),
                label: const Text('Add Syllabus'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        if (_plans.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No syllabus added yet.')),
            ),
          )
        else
          for (final plan in _plans)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    plan.isPublished
                        ? Icons.public_outlined
                        : Icons.edit_note_outlined,
                  ),
                ),
                title: Text(
                  plan.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${plan.academicSession} • '
                  '${plan.isPublished ? 'Published for teachers and parents' : 'Draft'}',
                ),
                onTap: () => setState(() {
                  _editingPlan = plan;
                  _title.text = plan.title;
                }),
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_canManage)
                      Switch.adaptive(
                        value: plan.isPublished,
                        onChanged: (_) => _togglePublish(plan),
                      ),
                    if (_canManage)
                      Text(plan.isPublished ? 'Published' : 'Publish'),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _editingPlan = plan;
                        _title.text = plan.title;
                      }),
                      icon: Icon(
                        _canManage
                            ? Icons.edit_outlined
                            : Icons.visibility_outlined,
                      ),
                      label: Text(_canManage ? 'Open' : 'View'),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Future<void> _createPlan() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Syllabus'),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: (_) => setDialogState(() {}),
              decoration: const InputDecoration(
                labelText: 'Syllabus Name',
                hintText: 'Summer Vacations, Mid Term, Final Exam...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;

    final now = DateTime.now();
    final plan = SyllabusPlanEntity(
      id: sl<SyllabusRepository>().generatePlanId(),
      academicSession: _session.text.trim(),
      title: name,
      isPublished: false,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await sl<SyllabusRepository>().savePlan(plan);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      setState(() {
        _editingPlan = _plans.where((item) => item.id == plan.id).firstOrNull;
        _title.text = plan.title;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Syllabus could not be created: $error')),
        );
      }
    }
  }

  Future<void> _togglePublish(SyllabusPlanEntity plan) async {
    final publish = !plan.isPublished;
    final now = DateTime.now();
    try {
      await sl<SyllabusRepository>().savePlan(
        plan.copyWith(
          isPublished: publish,
          updatedAt: now,
          publishedAt: publish ? now : null,
          clearPublishedAt: !publish,
        ),
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              publish
                  ? 'Syllabus published for teachers and parents.'
                  : 'Syllabus unpublished.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Publish status could not be changed: $error'),
          ),
        );
      }
    }
  }

  Widget _toolbar() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _editingPlan = null;
              _title.clear();
            }),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Syllabus List'),
          ),
          Text(
            _editingPlan!.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Chip(label: Text(_editingPlan!.academicSession)),
          if (_canManage)
            FilledButton.icon(
              onPressed: () => setState(() {
                _editingPlan = null;
                _title.clear();
              }),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save & Return'),
            ),
          const Chip(
            avatar: Icon(Icons.check_circle, color: Colors.green),
            label: Text('Syllabus added'),
          ),
          const Chip(
            avatar: Icon(Icons.add_circle_outline, color: Colors.orange),
            label: Text('Syllabus pending'),
          ),
        ],
      ),
    ),
  );

  Widget _classRow(SectionEntity section) {
    final academicClass = _class(section.classId)!;
    final subjects = _subjectsFor(section);
    final entries = _entries
        .where(
          (item) =>
              item.classId == academicClass.id && item.sectionId == section.id,
        )
        .toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class ${academicClass.name}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text('Section ${section.name}'),
                ],
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final subject in subjects)
                    _subjectButton(
                      academicClass,
                      section,
                      subject,
                      _entry(entries, subject),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: () =>
                  _preview(academicClass, section, subjects, entries),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Preview'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subjectButton(
    AcademicClassEntity academicClass,
    SectionEntity section,
    AcademicSubjectEntity subject,
    SyllabusEntryEntity? existing,
  ) {
    void callback() => _edit(academicClass, section, subject, existing);
    return existing == null
        ? OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFF59E0B)),
            ),
            onPressed: _canManage ? callback : null,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(subject.name),
          )
        : FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
            ),
            onPressed: _canManage ? callback : null,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(subject.name),
          );
  }

  Future<void> _edit(
    AcademicClassEntity academicClass,
    SectionEntity section,
    AcademicSubjectEntity subject,
    SyllabusEntryEntity? existing,
  ) async {
    final controller = TextEditingController(text: existing?.content ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${_title.text.trim()} - ${subject.name}'),
          content: SizedBox(
            width: 650,
            child: TextField(
              controller: controller,
              autofocus: true,
              minLines: 10,
              maxLines: 16,
              onChanged: (_) => setDialogState(() {}),
              decoration: const InputDecoration(
                labelText: 'Syllabus Content',
                hintText: 'Write chapters, topics, exercises or objectives...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'delete'),
                child: const Text('Remove'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, 'save'),
              child: const Text('Save Syllabus'),
            ),
          ],
        ),
      ),
    );
    if (result == null) {
      controller.dispose();
      return;
    }
    setState(() => _saving = true);
    try {
      if (result == 'delete' && existing != null) {
        await sl<SyllabusRepository>().deleteEntry(existing.id);
      } else if (result == 'save') {
        final now = DateTime.now();
        await sl<SyllabusRepository>().saveEntry(
          SyllabusEntryEntity(
            id: existing?.id ?? sl<SyllabusRepository>().generateId(),
            planId: _editingPlan!.id,
            academicSession: _session.text.trim(),
            syllabusTitle: _editingPlan!.title,
            classId: academicClass.id,
            className: academicClass.name,
            sectionId: section.id,
            sectionName: section.name,
            subjectId: subject.id,
            subjectName: subject.name,
            content: controller.text.trim(),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
      }
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Syllabus could not be saved: $error')),
        );
      }
    } finally {
      controller.dispose();
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _preview(
    AcademicClassEntity academicClass,
    SectionEntity section,
    List<AcademicSubjectEntity> subjects,
    List<SyllabusEntryEntity> entries,
  ) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        '${_title.text.trim()} - Class ${academicClass.name} / ${section.name}',
      ),
      content: SizedBox(
        width: 760,
        height: 560,
        child: ListView.separated(
          itemCount: subjects.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final subject = subjects[index];
            final entry = _entry(entries, subject);
            return ListTile(
              leading: Icon(
                entry == null ? Icons.menu_book_outlined : Icons.check_circle,
                color: entry == null ? Colors.orange : Colors.green,
              ),
              title: Text(
                subject.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(entry?.content ?? 'Syllabus not added'),
            );
          },
        ),
      ),
      actions: [
        FilledButton.icon(
          onPressed: () => _pdf(academicClass, section, subjects, entries),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Generate PDF'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  Future<void> _pdf(
    AcademicClassEntity academicClass,
    SectionEntity section,
    List<AcademicSubjectEntity> subjects,
    List<SyllabusEntryEntity> entries,
  ) async {
    try {
      await const SyllabusPdfService().generateAndShare(
        title: _title.text.trim(),
        session: _session.text.trim(),
        className: academicClass.name,
        sectionName: section.name,
        subjects: [
          for (final subject in subjects)
            SyllabusPdfSubject(
              name: subject.name,
              content: _entry(entries, subject)?.content ?? '',
            ),
        ],
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF could not be generated: $error')),
        );
      }
    }
  }

  AcademicClassEntity? _class(String id) {
    for (final item in _classes) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<AcademicSubjectEntity> _subjectsFor(SectionEntity section) {
    final result = <String, AcademicSubjectEntity>{};
    for (final subject in _subjects.where(
      (item) =>
          item.isActive &&
          item.classId == section.classId &&
          (item.sectionId == null || item.sectionId == section.id),
    )) {
      final key = subject.name.trim().toLowerCase();
      if (result[key] == null || subject.sectionId == section.id) {
        result[key] = subject;
      }
    }
    return result.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  SyllabusEntryEntity? _entry(
    List<SyllabusEntryEntity> entries,
    AcademicSubjectEntity subject,
  ) {
    for (final item in entries) {
      if (item.subjectId == subject.id ||
          item.subjectName.trim().toLowerCase() ==
              subject.name.trim().toLowerCase()) {
        return item;
      }
    }
    return null;
  }
}
