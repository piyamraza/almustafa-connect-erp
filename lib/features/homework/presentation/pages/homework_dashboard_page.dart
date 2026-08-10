import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_class_order.dart';
import '../../domain/entities/homework_entity.dart';
import '../bloc/homework_bloc.dart';
import '../services/homework_diary_pdf_service.dart';
import '../widgets/syllabus_management_tab.dart';
import 'homework_form_page.dart';
import 'homework_submissions_dashboard_page.dart';

class HomeworkDashboardPage extends StatelessWidget {
  const HomeworkDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeworkBloc>()..add(const LoadHomework('2026-2027')),
      child: const _HomeworkDashboardView(),
    );
  }
}

class _HomeworkDashboardView extends StatefulWidget {
  const _HomeworkDashboardView();

  @override
  State<_HomeworkDashboardView> createState() => _HomeworkDashboardViewState();
}

class _HomeworkDashboardViewState extends State<_HomeworkDashboardView> {
  final _session = TextEditingController(text: '2026-2027');
  DateTime _selectedDate = DateTime.now();
  List<AcademicClassEntity> _classes = const [];
  List<SectionEntity> _sections = const [];
  List<AcademicSubjectEntity> _subjects = const [];
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
      ]);
      if (!mounted) return;
      setState(() {
        _classes = values[0] as List<AcademicClassEntity>;
        _sections = values[1] as List<SectionEntity>;
        _subjects = values[2] as List<AcademicSubjectEntity>;
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
                : <HomeworkEntity>[];
            return Stack(
              children: [
                TabBarView(
                  children: [
                    _dailyHomework(items),
                    const SyllabusManagementTab(),
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
          return section.isActive && academicClass?.isActive == true;
        }).toList()..sort((a, b) {
          final classCompare = compareAcademicClassNames(
            _classById(a.classId)?.name ?? '',
            _classById(b.classId)?.name ?? '',
          );
          return classCompare != 0 ? classCompare : a.name.compareTo(b.name);
        });

    return ListView(
      padding: const EdgeInsets.all(20),
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
                const Chip(
                  avatar: Icon(Icons.check_circle, color: Colors.green),
                  label: Text('Homework added'),
                ),
                const Chip(
                  avatar: Icon(Icons.add_circle_outline, color: Colors.orange),
                  label: Text('Homework pending'),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
    if (added) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
        ),
        onPressed: () => _openHomework(existing: existing),
        icon: const Icon(Icons.check_circle_outline),
        label: Text(subject.name),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFB45309),
        side: const BorderSide(color: Color(0xFFF59E0B)),
      ),
      onPressed: () => _openHomework(
        classId: academicClass.id,
        sectionId: section.id,
        subjectId: subject.id,
      ),
      icon: const Icon(Icons.add_circle_outline),
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
