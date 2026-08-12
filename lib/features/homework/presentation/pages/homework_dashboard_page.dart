import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_class_order.dart';
import '../../../teachers/domain/entities/teacher_assignment_entity.dart';
import '../../../teachers/domain/repositories/teacher_assignment_repository.dart';
import '../../domain/entities/homework_entity.dart';
import '../bloc/homework_bloc.dart';
import '../services/homework_diary_pdf_service.dart';
import '../widgets/syllabus_management_tab.dart';
import 'homework_form_page.dart';
import 'homework_submissions_dashboard_page.dart';

class HomeworkDashboardPage extends StatelessWidget {
  const HomeworkDashboardPage({super.key, this.teacherId});

  final String? teacherId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeworkBloc>()..add(const LoadHomework('2026-2027')),
      child: _HomeworkDashboardView(teacherId: teacherId),
    );
  }
}

class _HomeworkDashboardView extends StatefulWidget {
  const _HomeworkDashboardView({required this.teacherId});

  final String? teacherId;

  @override
  State<_HomeworkDashboardView> createState() => _HomeworkDashboardViewState();
}

class _HomeworkDashboardViewState extends State<_HomeworkDashboardView> {
  final _session = TextEditingController(text: '2026-2027');
  DateTime _selectedDate = DateTime.now();
  List<AcademicClassEntity> _classes = const [];
  List<SectionEntity> _sections = const [];
  List<AcademicSubjectEntity> _subjects = const [];
  List<TeacherAssignmentEntity> _teacherAssignments = const [];
  bool _structureLoading = true;
  String? _structureError;

  @override
  void initState() {
    super.initState();
    _loadStructure();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  Future<void> _loadStructure() async {
    try {
      final values = await Future.wait<Object>([
        sl<AcademicStructureRepository>().getClasses(),
        sl<AcademicStructureRepository>().getSections(),
        sl<AcademicStructureRepository>().getSubjects(),
        sl<TeacherAssignmentRepository>().getAssignments(),
      ]);
      if (!mounted) return;
      setState(() {
        _classes = values[0] as List<AcademicClassEntity>;
        _sections = values[1] as List<SectionEntity>;
        _subjects = values[2] as List<AcademicSubjectEntity>;
        _teacherAssignments = (values[3] as List<TeacherAssignmentEntity>)
            .where(
              (item) =>
                  widget.teacherId == null ||
                  item.teacherId == widget.teacherId,
            )
            .toList();
        _structureLoading = false;
        _structureError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _structureLoading = false;
        _structureError = error.toString();
      });
    }
  }

  void _loadHomework() {
    context.read<HomeworkBloc>().add(LoadHomework(_session.text.trim()));
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select daily homework date',
    );
    if (value != null) setState(() => _selectedDate = value);
  }

  Future<void> _openHomework({
    HomeworkEntity? existing,
    String? classId,
    String? sectionId,
    String? subjectId,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => HomeworkFormPage(
          existing: existing,
          academicSession: _session.text.trim(),
          initialClassId: classId,
          initialSectionId: sectionId,
          initialSubjectId: subjectId,
          initialAssignedDate: _selectedDate,
          lockedTeacherId: widget.teacherId,
        ),
      ),
    );
    if (saved == true && mounted) _loadHomework();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Homework & Syllabus'),
          actions: [
            const DashboardNavigationButton(),
            if (MediaQuery.sizeOf(context).width >= 620)
              TextButton.icon(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const HomeworkSubmissionsDashboardPage(),
                  ),
                ),
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: const Text('Submissions'),
              ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFCBD5E1),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              Tab(icon: Icon(Icons.menu_book_outlined), text: 'Daily Homework'),
              Tab(icon: Icon(Icons.school_outlined), text: 'Syllabus'),
            ],
          ),
        ),
        body: BlocConsumer<HomeworkBloc, HomeworkState>(
          listener: (context, state) {
            final message = switch (state) {
              HomeworkLoaded(:final message) => message,
              HomeworkError(:final message) => message,
              _ => null,
            };
            if (message != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(message)));
            }
          },
          builder: (context, state) {
            final items = state is HomeworkLoaded
                ? state.items
                      .where(
                        (item) =>
                            widget.teacherId == null ||
                            item.teacherId == widget.teacherId,
                      )
                      .toList()
                : <HomeworkEntity>[];
            return Stack(
              children: [
                TabBarView(
                  children: [
                    _dailyHomework(items),
                    SyllabusManagementTab(teacherId: widget.teacherId),
                  ],
                ),
                if (state is HomeworkLoading) const LinearProgressIndicator(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dailyHomework(List<HomeworkEntity> items) {
    if (_structureLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_structureError != null) {
      return Center(
        child: FilledButton.icon(
          onPressed: _loadStructure,
          icon: const Icon(Icons.refresh),
          label: Text('Retry: $_structureError'),
        ),
      );
    }

    final rows =
        _sections.where((section) {
          final academicClass = _classById(section.classId);
          return section.isActive &&
              academicClass?.isActive == true &&
              _teacherCanAccessSection(section);
        }).toList()..sort((a, b) {
          final classCompare = compareAcademicClassNames(
            _classById(a.classId)?.name ?? '',
            _classById(b.classId)?.name ?? '',
          );
          return classCompare != 0 ? classCompare : a.name.compareTo(b.name);
        });

    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 650 ? 12 : 20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 190,
                  child: TextField(
                    controller: _session,
                    decoration: const InputDecoration(
                      labelText: 'Academic Session',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(_date(_selectedDate)),
                ),
                FilledButton.icon(
                  onPressed: _loadHomework,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Load'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('No active classes found.')),
            ),
          )
        else
          for (final section in rows)
            _classDiaryRow(section: section, items: items),
      ],
    );
  }

  Widget _classDiaryRow({
    required SectionEntity section,
    required List<HomeworkEntity> items,
  }) {
    final academicClass = _classById(section.classId)!;
    final subjects = _subjectsFor(section);
    final dailyItems = items
        .where(
          (item) =>
              item.classId == academicClass.id &&
              item.sectionId == section.id &&
              _sameDay(item.assignedDate, _selectedDate),
        )
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 650 ? 10 : 16,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 650;
            final heading = SizedBox(
              width: compact ? double.infinity : 150,
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
            );
            final subjectList = Wrap(
              spacing: compact ? 6 : 8,
              runSpacing: compact ? 6 : 8,
              children: [
                for (final subject in subjects)
                  _subjectButton(
                    academicClass: academicClass,
                    section: section,
                    subject: subject,
                    existing: _homeworkForSubject(dailyItems, subject),
                  ),
              ],
            );
            final preview = FilledButton.tonalIcon(
              onPressed: () => _showPreview(
                academicClass: academicClass,
                section: section,
                subjects: subjects,
                items: dailyItems,
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Preview'),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  const SizedBox(height: 6),
                  subjectList,
                  const SizedBox(height: 8),
                  preview,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class ${academicClass.name}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
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
                          academicClass: academicClass,
                          section: section,
                          subject: subject,
                          existing: _homeworkForSubject(dailyItems, subject),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _showPreview(
                    academicClass: academicClass,
                    section: section,
                    subjects: subjects,
                    items: dailyItems,
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Preview'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _subjectButton({
    required AcademicClassEntity academicClass,
    required SectionEntity section,
    required AcademicSubjectEntity subject,
    required HomeworkEntity? existing,
  }) {
    final added = existing != null;
    final compact = MediaQuery.sizeOf(context).width < 650;
    if (added) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          minimumSize: Size.zero,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 16,
            vertical: compact ? 7 : 10,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: TextStyle(
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () => _openHomework(existing: existing),
        icon: Icon(Icons.check_circle_outline, size: compact ? 16 : 20),
        label: Text(subject.name),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFB45309),
        side: const BorderSide(color: Color(0xFFF59E0B)),
        minimumSize: Size.zero,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 16,
          vertical: compact ? 7 : 10,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: TextStyle(
          fontSize: compact ? 12 : 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: () => _openHomework(
        classId: academicClass.id,
        sectionId: section.id,
        subjectId: subject.id,
      ),
      icon: Icon(Icons.add_circle_outline, size: compact ? 16 : 20),
      label: Text(subject.name),
    );
  }

  Future<void> _showPreview({
    required AcademicClassEntity academicClass,
    required SectionEntity section,
    required List<AcademicSubjectEntity> subjects,
    required List<HomeworkEntity> items,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${academicClass.name} - ${section.name} • Daily Diary'),
        content: SizedBox(
          width: 760,
          height: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _date(_selectedDate),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: subjects.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final subject = subjects[index];
                    final homework = _homeworkForSubject(items, subject);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: homework == null
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        child: Icon(
                          homework == null ? Icons.menu_book : Icons.check,
                          color: homework == null
                              ? Colors.orange.shade800
                              : Colors.green.shade700,
                        ),
                      ),
                      title: Text(
                        subject.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: homework == null
                          ? const Text('No homework added')
                          : Text(
                              '${homework.title}\n${homework.description}'
                              '${homework.instructions.isEmpty ? '' : '\n${homework.instructions}'}',
                            ),
                      isThreeLine: homework != null,
                      trailing: homework == null
                          ? null
                          : IconButton(
                              tooltip: 'Edit homework',
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _openHomework(existing: homework);
                              },
                              icon: const Icon(Icons.edit_outlined),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () async {
              try {
                await const HomeworkDiaryPdfService().generateAndShare(
                  className: academicClass.name,
                  sectionName: section.name,
                  date: _selectedDate,
                  subjects: [
                    for (final subject in subjects)
                      HomeworkDiarySubject(
                        subjectName: subject.name,
                        homework: _homeworkForSubject(items, subject),
                      ),
                  ],
                );
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('PDF could not be generated: $error'),
                    ),
                  );
                }
              }
            },
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
  }

  AcademicClassEntity? _classById(String id) {
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
      if (!_teacherCanAccessSubject(section, subject)) continue;
      final key = subject.name.trim().toLowerCase();
      final current = result[key];
      if (current == null || subject.sectionId == section.id) {
        result[key] = subject;
      }
    }
    final values = result.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return values;
  }

  bool _teacherCanAccessSection(SectionEntity section) {
    if (widget.teacherId == null) return true;
    final academicClass = _classById(section.classId);
    return _teacherAssignments.any(
      (item) =>
          _matches(item.classId, section.classId, academicClass?.name ?? '') &&
          _matches(item.sectionId, section.id, section.name),
    );
  }

  bool _teacherCanAccessSubject(
    SectionEntity section,
    AcademicSubjectEntity subject,
  ) {
    if (widget.teacherId == null) return true;
    final academicClass = _classById(section.classId);
    return _teacherAssignments.any(
      (item) =>
          _matches(item.classId, section.classId, academicClass?.name ?? '') &&
          _matches(item.sectionId, section.id, section.name) &&
          item.subject.trim().toLowerCase() ==
              subject.name.trim().toLowerCase(),
    );
  }

  static bool _matches(String value, String id, String name) {
    final normalized = value.trim().toLowerCase();
    return normalized == id.trim().toLowerCase() ||
        normalized == name.trim().toLowerCase();
  }

  HomeworkEntity? _homeworkForSubject(
    List<HomeworkEntity> items,
    AcademicSubjectEntity subject,
  ) {
    final matches =
        items
            .where(
              (item) =>
                  item.subjectId == subject.id ||
                  item.subjectName.trim().toLowerCase() ==
                      subject.name.trim().toLowerCase(),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return matches.isEmpty ? null : matches.first;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
