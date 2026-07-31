import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/exam_mark_entity.dart';
import '../bloc/exam_marks_bloc.dart';
import '../bloc/exam_marks_event.dart';
import '../bloc/exam_marks_state.dart';

class MarksEntryPage extends StatelessWidget {
  const MarksEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExamMarksBloc>(
      create: (_) => sl<ExamMarksBloc>()..add(const LoadMarksEntry()),
      child: const _MarksEntryView(),
    );
  }
}

class _MarksEntryView extends StatefulWidget {
  const _MarksEntryView();

  @override
  State<_MarksEntryView> createState() => _MarksEntryViewState();
}

class _MarksEntryViewState extends State<_MarksEntryView> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};
  final Set<String> _absentStudentIds = {};

  String? _loadedSetupId;
  String _loadedMarksSignature = '';

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _marksControllers.values) {
      controller.dispose();
    }
    for (final controller in _remarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _synchroniseControllers(ExamMarksLoaded state) {
    final setupId = state.selectedSubjectSetupId;
    final signature = [
      ...state.students.map((student) => student.id),
      ...state.marks.map(
        (mark) => '${mark.id}:${mark.updatedAt.microsecondsSinceEpoch}',
      ),
    ].join('|');
    if (_loadedSetupId == setupId && _loadedMarksSignature == signature) return;

    for (final controller in _marksControllers.values) {
      controller.dispose();
    }
    for (final controller in _remarksControllers.values) {
      controller.dispose();
    }
    _marksControllers.clear();
    _remarksControllers.clear();
    _absentStudentIds.clear();

    for (final student in state.students) {
      final mark = state.markForStudent(student.id);
      _marksControllers[student.id] = TextEditingController(
        text: mark == null ? '' : _formatNumber(mark.obtainedMarks),
      );
      _remarksControllers[student.id] = TextEditingController(
        text: mark?.remarks ?? '',
      );
      if (mark?.isAbsent ?? false) {
        _absentStudentIds.add(student.id);
      }
    }
    _loadedSetupId = setupId;
    _loadedMarksSignature = signature;
  }

  void _toggleAbsent(String studentId, bool isAbsent) {
    final marksController = _marksControllers[studentId]!;
    setState(() {
      if (isAbsent) {
        _absentStudentIds.add(studentId);
        marksController.text = '0';
      } else {
        _absentStudentIds.remove(studentId);
        marksController.clear();
      }
    });
  }

  Future<void> _save(ExamMarksLoaded state) async {
    final setup = state.selectedSubjectSetup;
    final exam = state.selectedExam;
    if (setup == null || exam == null) return;

    final now = DateTime.now();
    final marks = <ExamMarkEntity>[];
    for (final student in state.students) {
      final isAbsent = _absentStudentIds.contains(student.id);
      final input = _marksControllers[student.id]!.text.trim();
      final obtainedMarks = isAbsent ? 0.0 : double.tryParse(input);
      if (obtainedMarks == null) {
        _showMessage('Enter obtained marks for ${student.fullName}.');
        return;
      }
      if (obtainedMarks < 0 || obtainedMarks > setup.totalMarks) {
        _showMessage(
          'Marks for ${student.fullName} must be between 0 and ${_formatNumber(setup.totalMarks)}.',
        );
        return;
      }

      final existing = state.markForStudent(student.id);
      final entryKey = ExamMarkEntity.entryKeyFor(
        examId: exam.id,
        classId: setup.classId,
        sectionId: setup.sectionId,
        subjectId: setup.subjectId,
      );
      marks.add(
        ExamMarkEntity(
          id: ExamMarkEntity.documentIdFor(
            examId: exam.id,
            classId: setup.classId,
            sectionId: setup.sectionId,
            subjectId: setup.subjectId,
            studentId: student.id,
          ),
          entryKey: entryKey,
          examId: exam.id,
          examName: exam.name,
          academicSession: exam.academicSession,
          classId: setup.classId,
          className: setup.className,
          sectionId: setup.sectionId,
          sectionName: setup.sectionName,
          subjectId: setup.subjectId,
          subjectName: setup.subjectName,
          studentId: student.id,
          rollNumber: student.rollNumber,
          studentName: student.fullName,
          admissionNo: student.admissionNo,
          obtainedMarks: obtainedMarks,
          isAbsent: isAbsent,
          remarks: _remarksControllers[student.id]!.text.trim(),
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }
    context.read<ExamMarksBloc>().add(SaveMarksEntry(marks));
  }

  Future<void> _confirmDelete(ExamMarkEntity mark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Marks'),
        content: Text('Delete marks for ${mark.studentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ExamMarksBloc>().add(DeleteExamMarkEntry(mark.id));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marks Entry'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context.read<ExamMarksBloc>().add(
                  const RefreshMarksEntry(),
                ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<ExamMarksBloc, ExamMarksState>(
        listener: (context, state) {
          if (state is! ExamMarksLoaded) return;
          final message = state.errorMessage ?? state.successMessage;
          if (message != null) _showMessage(message);
        },
        builder: (context, state) {
          if (state is ExamMarksInitial || state is ExamMarksLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExamMarksFailure) {
            return _FailureView(
              message: state.message,
              onRetry: () => context.read<ExamMarksBloc>().add(
                    const LoadMarksEntry(),
                  ),
            );
          }

          final data = state as ExamMarksLoaded;
          _synchroniseControllers(data);
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SelectionPanel(data: data),
                  const SizedBox(height: 12),
                  _SearchField(
                    controller: _searchController,
                    enabled: data.selectedSubjectSetup != null,
                    onChanged: (query) => context
                        .read<ExamMarksBloc>()
                        .add(SearchMarksStudents(query)),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildContent(data)),
                  const SizedBox(height: 12),
                  _SaveBar(
                    enabled: data.selectedSubjectSetup != null &&
                        data.students.isNotEmpty &&
                        !data.isLoading &&
                        !data.isSaving,
                    isSaving: data.isSaving,
                    onSave: () => _save(data),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ExamMarksLoaded data) {
    if (data.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data.selectedSubjectSetup == null) {
      return const _EmptyMarksView(
        icon: Icons.filter_alt_outlined,
        message: 'Select exam, class, section and subject to load students.',
      );
    }
    if (data.students.isEmpty) {
      return const _EmptyMarksView(
        icon: Icons.groups_outlined,
        message: 'No active students found for the selected class and section.',
      );
    }
    if (data.visibleStudents.isEmpty) {
      return const _EmptyMarksView(
        icon: Icons.search_off_outlined,
        message: 'No students match your search.',
      );
    }
    return _MarksTable(
      data: data,
      marksControllers: _marksControllers,
      remarksControllers: _remarksControllers,
      absentStudentIds: _absentStudentIds,
      onAbsentChanged: _toggleAbsent,
      onDelete: _confirmDelete,
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({required this.data});

  final ExamMarksLoaded data;

  @override
  Widget build(BuildContext context) {
    final setup = data.selectedSubjectSetup;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Marks Entry', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MarksSelect(
                  label: 'Exam',
                  value: data.selectedExamId,
                  items: data.availableExams
                      .map((exam) => _SelectItem(
                            id: exam.id,
                            label: '${exam.name} (${exam.academicSession})',
                          ))
                      .toList(growable: false),
                  onChanged: data.isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            context.read<ExamMarksBloc>().add(SelectMarksExam(value));
                          }
                        },
                ),
                _MarksSelect(
                  label: 'Class',
                  value: data.selectedClassId,
                  items: data.availableClasses
                      .map((setup) => _SelectItem(
                            id: setup.classId,
                            label: setup.className,
                          ))
                      .toList(growable: false),
                  onChanged: data.selectedExamId == null || data.isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            context.read<ExamMarksBloc>().add(SelectMarksClass(value));
                          }
                        },
                ),
                _MarksSelect(
                  label: 'Section',
                  value: data.selectedSectionId,
                  items: data.availableSections
                      .map((setup) => _SelectItem(
                            id: setup.sectionId,
                            label: setup.sectionName,
                          ))
                      .toList(growable: false),
                  onChanged: data.selectedClassId == null || data.isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            context.read<ExamMarksBloc>().add(SelectMarksSection(value));
                          }
                        },
                ),
                _MarksSelect(
                  label: 'Subject',
                  value: data.selectedSubjectSetupId,
                  items: data.availableSubjects
                      .map((setup) => _SelectItem(
                            id: setup.id,
                            label: '${setup.subjectName} (Total ${_formatNumber(setup.totalMarks)})',
                          ))
                      .toList(growable: false),
                  onChanged: data.selectedSectionId == null || data.isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            context.read<ExamMarksBloc>().add(SelectMarksSubject(value));
                          }
                        },
                ),
              ],
            ),
            if (setup != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Subject: ${setup.subjectName}')),
                  Chip(label: Text('Total: ${_formatNumber(setup.totalMarks)}')),
                  Chip(label: Text('Passing: ${_formatNumber(setup.passingMarks)}')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarksTable extends StatelessWidget {
  const _MarksTable({
    required this.data,
    required this.marksControllers,
    required this.remarksControllers,
    required this.absentStudentIds,
    required this.onAbsentChanged,
    required this.onDelete,
  });

  final ExamMarksLoaded data;
  final Map<String, TextEditingController> marksControllers;
  final Map<String, TextEditingController> remarksControllers;
  final Set<String> absentStudentIds;
  final void Function(String studentId, bool isAbsent) onAbsentChanged;
  final ValueChanged<ExamMarkEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return _MobileMarksList(
            data: data,
            marksControllers: marksControllers,
            remarksControllers: remarksControllers,
            absentStudentIds: absentStudentIds,
            onAbsentChanged: onAbsentChanged,
            onDelete: onDelete,
          );
        }
        return _DesktopMarksTable(
          data: data,
          marksControllers: marksControllers,
          remarksControllers: remarksControllers,
          absentStudentIds: absentStudentIds,
          onAbsentChanged: onAbsentChanged,
          onDelete: onDelete,
        );
      },
    );
  }
}

class _DesktopMarksTable extends StatelessWidget {
  const _DesktopMarksTable({
    required this.data,
    required this.marksControllers,
    required this.remarksControllers,
    required this.absentStudentIds,
    required this.onAbsentChanged,
    required this.onDelete,
  });

  final ExamMarksLoaded data;
  final Map<String, TextEditingController> marksControllers;
  final Map<String, TextEditingController> remarksControllers;
  final Set<String> absentStudentIds;
  final void Function(String studentId, bool isAbsent) onAbsentChanged;
  final ValueChanged<ExamMarkEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    final totalMarks = data.selectedSubjectSetup!.totalMarks;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const rollWidth = 80.0;
          const admissionWidth = 150.0;
          const marksWidth = 135.0;
          const absentWidth = 88.0;
          const remarksWidth = 230.0;
          const deleteWidth = 48.0;
          const fixedWidth = rollWidth + admissionWidth + marksWidth + absentWidth + remarksWidth + deleteWidth;
          final nameWidth = (constraints.maxWidth - fixedWidth - 32)
              .clamp(180.0, double.infinity)
              .toDouble();
          return Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const SizedBox(width: rollWidth, child: Text('Roll No', style: TextStyle(fontWeight: FontWeight.w700))),
                    const SizedBox(width: admissionWidth, child: Text('Admission No', style: TextStyle(fontWeight: FontWeight.w700))),
                    SizedBox(width: nameWidth, child: const Text('Student Name', style: TextStyle(fontWeight: FontWeight.w700))),
                    SizedBox(
                      width: marksWidth,
                      child: Text(
                        'Obtained / ${_formatNumber(totalMarks)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: absentWidth, child: Text('Absent', style: TextStyle(fontWeight: FontWeight.w700))),
                    const SizedBox(width: remarksWidth, child: Text('Remarks', style: TextStyle(fontWeight: FontWeight.w700))),
                    const SizedBox(width: deleteWidth),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: data.visibleStudents.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = data.visibleStudents[index];
                    final mark = data.markForStudent(student.id);
                    final isAbsent = absentStudentIds.contains(student.id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(width: rollWidth, child: Text(student.rollNumber.isEmpty ? '-' : student.rollNumber)),
                          SizedBox(width: admissionWidth, child: Text(student.admissionNo)),
                          SizedBox(width: nameWidth, child: Text(student.fullName, overflow: TextOverflow.ellipsis)),
                          SizedBox(
                            width: marksWidth,
                            child: _MarksInput(
                              controller: marksControllers[student.id]!,
                              enabled: !isAbsent,
                              totalMarks: totalMarks,
                            ),
                          ),
                          SizedBox(
                            width: absentWidth,
                            child: Checkbox(
                              value: isAbsent,
                              onChanged: (value) => onAbsentChanged(student.id, value ?? false),
                            ),
                          ),
                          SizedBox(
                            width: remarksWidth,
                            child: TextField(
                              controller: remarksControllers[student.id]!,
                              maxLength: 160,
                              decoration: const InputDecoration(
                                hintText: 'Optional',
                                counterText: '',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: deleteWidth,
                            child: mark == null
                                ? const SizedBox.shrink()
                                : IconButton(
                                    tooltip: 'Delete marks',
                                    onPressed: () => onDelete(mark),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MobileMarksList extends StatelessWidget {
  const _MobileMarksList({
    required this.data,
    required this.marksControllers,
    required this.remarksControllers,
    required this.absentStudentIds,
    required this.onAbsentChanged,
    required this.onDelete,
  });

  final ExamMarksLoaded data;
  final Map<String, TextEditingController> marksControllers;
  final Map<String, TextEditingController> remarksControllers;
  final Set<String> absentStudentIds;
  final void Function(String studentId, bool isAbsent) onAbsentChanged;
  final ValueChanged<ExamMarkEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    final totalMarks = data.selectedSubjectSetup!.totalMarks;
    return ListView.separated(
      itemCount: data.visibleStudents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = data.visibleStudents[index];
        final mark = data.markForStudent(student.id);
        final isAbsent = absentStudentIds.contains(student.id);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(student.fullName, style: Theme.of(context).textTheme.titleSmall),
                    ),
                    if (mark != null)
                      IconButton(
                        tooltip: 'Delete marks',
                        onPressed: () => onDelete(mark),
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
                Text('Roll: ${student.rollNumber.isEmpty ? '-' : student.rollNumber} • ${student.admissionNo}'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MarksInput(
                        controller: marksControllers[student.id]!,
                        enabled: !isAbsent,
                        totalMarks: totalMarks,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Checkbox(
                          value: isAbsent,
                          onChanged: (value) => onAbsentChanged(student.id, value ?? false),
                        ),
                        const Text('Absent'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: remarksControllers[student.id]!,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (optional)',
                    counterText: '',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MarksInput extends StatelessWidget {
  const _MarksInput({
    required this.controller,
    required this.enabled,
    required this.totalMarks,
  });

  final TextEditingController controller;
  final bool enabled;
  final double totalMarks;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Marks',
        hintText: '0 - ${_formatNumber(totalMarks)}',
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _MarksSelect extends StatelessWidget {
  const _MarksSelect({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<_SelectItem> items;
  final ValueChanged<String?>? onChanged;

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
              (item) => DropdownMenuItem<String>(
                value: item.id,
                child: Text(item.label, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search by roll no, admission no or student name...',
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.clear),
              ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.enabled,
    required this.isSaving,
    required this.onSave,
  });

  final bool enabled;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: enabled ? onSave : null,
        icon: isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(isSaving ? 'Saving Marks...' : 'Save All Marks'),
      ),
    );
  }
}

class _EmptyMarksView extends StatelessWidget {
  const _EmptyMarksView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

class _SelectItem {
  const _SelectItem({required this.id, required this.label});

  final String id;
  final String label;
}

String _formatNumber(double value) {
  return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}
