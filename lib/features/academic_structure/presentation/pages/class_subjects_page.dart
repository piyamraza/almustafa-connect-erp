import 'package:flutter/material.dart';

import '../../domain/entities/academic_class_entity.dart';
import '../../domain/entities/academic_subject_entity.dart';
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
  late Future<List<AcademicSubjectEntity>> _subjectsFuture;
  bool _copying = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _subjectsFuture = widget.repository.getSubjectsForClass(widget.academicClass.id);
  }

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
          name: name,
          isActive: isActive,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
      if (mounted) {
        setState(_reload);
        _showMessage(existing == null ? 'Subject added.' : 'Subject updated.');
      }
    } catch (error) {
      _showMessage(_errorMessage(error));
    }
  }

  Future<void> _copySubjects() async {
    setState(() => _copying = true);
    try {
      final classes = await widget.repository.getClasses();
      final choices = classes
          .where((value) => value.id != widget.academicClass.id)
          .toList(growable: false);
      if (!mounted) return;
      if (choices.isEmpty) {
        _showMessage('Add another class before copying subjects.');
        return;
      }

      String? sourceClassId;
      final selected = await showDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Copy Subjects From Class'),
            content: DropdownButtonFormField<String>(
              value: sourceClassId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Source class',
                border: OutlineInputBorder(),
              ),
              items: choices
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value.id,
                      child: Text(value.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) => setDialogState(() => sourceClassId = value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: sourceClassId == null
                    ? null
                    : () => Navigator.pop(dialogContext, sourceClassId),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy Subjects'),
              ),
            ],
          ),
        ),
      );
      if (selected == null) return;

      final copied = await widget.repository.copySubjects(
        sourceClassId: selected,
        targetClassId: widget.academicClass.id,
      );
      if (mounted) {
        setState(_reload);
        _showMessage(
          copied == 0
              ? 'All subjects from the selected class already exist.'
              : '$copied subject${copied == 1 ? '' : 's'} copied successfully.',
        );
      }
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  Future<void> _deleteSubject(AcademicSubjectEntity subject) async {
    final approved = await showDialog<bool>(
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
      if (mounted) {
        setState(_reload);
        _showMessage('Subject deleted.');
      }
    } catch (error) {
      _showMessage(_errorMessage(error));
    }
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
      appBar: AppBar(title: Text('${widget.academicClass.name} Subjects')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _saveSubject(),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
      body: FutureBuilder<List<AcademicSubjectEntity>>(
        future: _subjectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(_errorMessage(snapshot.error!)));
          }
          final subjects = snapshot.data ?? const <AcademicSubjectEntity>[];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _copying ? null : _copySubjects,
                    icon: _copying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.copy_outlined),
                    label: Text(_copying ? 'Copying...' : 'Copy Subjects From Class'),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: subjects.isEmpty
                      ? const Center(
                          child: Text('No subjects added for this class yet.'),
                        )
                      : ListView.separated(
                          itemCount: subjects.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final subject = subjects[index];
                            return Card(
                              child: ListTile(
                                title: Text(subject.name),
                                leading: const Icon(Icons.menu_book_outlined),
                                trailing: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Chip(
                                      label: Text(subject.isActive ? 'Active' : 'Inactive'),
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
