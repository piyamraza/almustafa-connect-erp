import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../domain/entities/academic_class_entity.dart';
import '../../domain/entities/academic_subject_entity.dart';
import '../../domain/entities/section_entity.dart';
import '../../domain/repositories/academic_structure_repository.dart';

class ClassSubjectsPage extends StatefulWidget {
  const ClassSubjectsPage({
    super.key,
    required this.academicClass,
    required this.repository,
  });

  final AcademicClassEntity academicClass;
  final AcademicStructureRepository repository;

  @override
  State<ClassSubjectsPage> createState() => _ClassSubjectsPageState();
}

class _ClassSubjectsPageState extends State<ClassSubjectsPage> {
  static const _classDefaultScope = '__class_default_subjects__';

  late Future<_SubjectPageData> _pageFuture;
  String? _selectedSectionId;
  String? _sourceClassId;
  String? _sourceSectionId;
  bool _copying = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _pageFuture = _loadPageData();
  }

  Future<_SubjectPageData> _loadPageData() async {
    final values = await Future.wait<Object>([
      widget.repository.getClasses(),
      widget.repository.getSections(),
      _selectedSectionId == null
          ? widget.repository.getSubjectsForClass(widget.academicClass.id)
          : widget.repository.getSubjectsForClassSection(
              widget.academicClass.id,
              _selectedSectionId!,
            ),
    ]);
    final classes = (values[0] as List<AcademicClassEntity>)
        .where((academicClass) => academicClass.isActive)
        .toList()
      ..sort((first, second) => first.name.compareTo(second.name));
    final allSections = values[1] as List<SectionEntity>;
    final sections = allSections
        .where(
          (section) =>
              section.classId == widget.academicClass.id && section.isActive,
        )
        .toList()
      ..sort((first, second) => first.name.compareTo(second.name));
    final subjects = values[2] as List<AcademicSubjectEntity>;
    return _SubjectPageData(
      classes: classes,
      allSections: allSections,
      sections: sections,
      subjects: subjects,
    );
  }

  String get _scopeLabel => _selectedSectionId == null
      ? 'Class Defaults'
      : 'Selected Section';

  Future<void> _saveSubject({AcademicSubjectEntity? existing}) async {
    final controller = TextEditingController(text: existing?.name ?? '');
    var isActive = existing?.isActive ?? true;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Subject' : 'Edit Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Subject name',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: isActive,
                onChanged: (value) => setDialogState(() => isActive = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    final now = DateTime.now();
    try {
      await widget.repository.saveSubject(
        AcademicSubjectEntity(
          id: existing?.id ?? widget.repository.generateSubjectId(),
          classId: widget.academicClass.id,
          sectionId: _selectedSectionId,
          name: name,
          isActive: isActive,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      setState(_reload);
      _showMessage(existing == null ? 'Subject added.' : 'Subject updated.');
    } catch (error) {
      _showMessage(_errorMessage(error));
    }
  }

  Future<void> _copySubjects() async {
    final sourceClassId = _sourceClassId;
    if (sourceClassId == null) {
      _showMessage('Select the class to copy subjects from.');
      return;
    }
    setState(() => _copying = true);
    try {
      final copied = await widget.repository.copySubjects(
        sourceClassId: sourceClassId,
        targetClassId: widget.academicClass.id,
        sourceSectionId: _sourceSectionId,
        targetSectionId: _selectedSectionId,
      );
      if (!mounted) return;
      setState(_reload);
      _showMessage(
        copied == 0
            ? 'All subjects from the selected list already exist here.'
            : '$copied subject${copied == 1 ? '' : 's'} copied successfully.',
      );
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  Future<void> _deleteSubject(AcademicSubjectEntity subject) async {
    final approved =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Subject'),
            content: Text('Delete ${subject.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!approved) return;
    try {
      await widget.repository.deleteSubject(subject.id);
      if (!mounted) return;
      setState(_reload);
      _showMessage('Subject deleted.');
    } catch (error) {
      _showMessage(_errorMessage(error));
    }
  }

  void _selectScope(String value) {
    setState(() {
      _selectedSectionId = value == _classDefaultScope ? null : value;
      _reload();
    });
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _errorMessage(Object error) {
    return error.toString().replaceFirst('StateError: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: Text('${widget.academicClass.name} Subjects')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _saveSubject(),
        icon: const Icon(Icons.add),
        label: Text(
          _selectedSectionId == null ? 'Add Default Subject' : 'Add Section Subject',
        ),
      ),
      body: FutureBuilder<_SubjectPageData>(
        future: _pageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(_errorMessage(snapshot.error!)));
          }
          final data = snapshot.data!;
          final selectedScopeStillExists = _selectedSectionId == null ||
              data.sections.any((section) => section.id == _selectedSectionId);
          final selectedScope = selectedScopeStillExists
              ? _selectedSectionId ?? _classDefaultScope
              : _classDefaultScope;
          final matchingSections = data.sections
              .where((section) => section.id == _selectedSectionId)
              .toList(growable: false);
          final sectionName =
              matchingSections.isEmpty ? null : matchingSections.first.name;
          final sourceClassId = data.classes
                  .any((academicClass) => academicClass.id == _sourceClassId)
              ? _sourceClassId
              : null;
          final sourceSections = <SectionEntity>[
            if (sourceClassId != null)
              ...data.allSections.where(
                (section) =>
                    section.isActive && section.classId == sourceClassId,
              ),
          ]..sort((first, second) => first.name.compareTo(second.name));
          final sourceScope = sourceSections
                  .any((section) => section.id == _sourceSectionId)
              ? _sourceSectionId ?? _classDefaultScope
              : _classDefaultScope;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: constraints.maxWidth >= 620
                                ? 320
                                : constraints.maxWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedScope,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Manage subjects for',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: _classDefaultScope,
                                  child: Text('Class defaults (all sections)'),
                                ),
                                ...data.sections.map(
                                  (section) => DropdownMenuItem<String>(
                                    value: section.id,
                                    child: Text('${section.name} section only'),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) _selectScope(value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth >= 620
                                ? 260
                                : constraints.maxWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: sourceClassId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Copy subjects from class',
                                border: OutlineInputBorder(),
                              ),
                              items: data.classes
                                  .map(
                                    (academicClass) => DropdownMenuItem<String>(
                                      value: academicClass.id,
                                      child: Text(academicClass.name),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) => setState(() {
                                _sourceClassId = value;
                                _sourceSectionId = null;
                              }),
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth >= 620
                                ? 260
                                : constraints.maxWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: sourceScope,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Copy list',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: _classDefaultScope,
                                  child: Text('Class defaults'),
                                ),
                                ...sourceSections.map(
                                  (section) => DropdownMenuItem<String>(
                                    value: section.id,
                                    child: Text('${section.name} section'),
                                  ),
                                ),
                              ],
                              onChanged: sourceClassId == null
                                  ? null
                                  : (value) => setState(
                                        () => _sourceSectionId =
                                            value == _classDefaultScope
                                                ? null
                                                : value,
                                      ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _copying || sourceClassId == null
                                ? null
                                : _copySubjects,
                            icon: _copying
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.copy_outlined),
                            label: Text(
                              _copying
                                  ? 'Copying...'
                                  : _selectedSectionId == null
                                  ? 'Copy to Class Defaults'
                                  : 'Copy to Selected Section',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectedSectionId == null
                        ? 'Class defaults are used by every section unless that section has its own subject list.'
                        : '${sectionName ?? _scopeLabel} has its own subject list. Only this section will use these subjects.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: data.subjects.isEmpty
                      ? Center(
                          child: Text(
                            _selectedSectionId == null
                                ? 'No default subjects added for this class yet.'
                                : 'No section-specific subjects added yet.',
                          ),
                        )
                      : ListView.separated(
                          itemCount: data.subjects.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final subject = data.subjects[index];
                            return Card(
                              child: ListTile(
                                title: Text(subject.name),
                                leading: const Icon(Icons.menu_book_outlined),
                                trailing: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Chip(
                                      label: Text(
                                        subject.isActive ? 'Active' : 'Inactive',
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      tooltip: 'Edit subject',
                                      onPressed: () => _saveSubject(existing: subject),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete subject',
                                      onPressed: () => _deleteSubject(subject),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SubjectPageData {
  const _SubjectPageData({
    required this.classes,
    required this.allSections,
    required this.sections,
    required this.subjects,
  });

  final List<AcademicClassEntity> classes;
  final List<SectionEntity> allSections;
  final List<SectionEntity> sections;
  final List<AcademicSubjectEntity> subjects;
}
