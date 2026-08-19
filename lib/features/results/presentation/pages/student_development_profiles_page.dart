import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../../access_control/domain/entities/app_permission.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../exams/domain/entities/exam_entity.dart';
import '../../../exams/domain/repositories/exam_repository.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../domain/entities/student_development_profile_entity.dart';
import '../../domain/repositories/student_development_profile_repository.dart';

class StudentDevelopmentProfilesPage extends StatefulWidget {
  const StudentDevelopmentProfilesPage({super.key});

  @override
  State<StudentDevelopmentProfilesPage> createState() =>
      _StudentDevelopmentProfilesPageState();
}

class _StudentDevelopmentProfilesPageState
    extends State<StudentDevelopmentProfilesPage> {
  final _profiles = <String, StudentDevelopmentProfileEntity>{};
  List<ExamEntity> _exams = const [];
  List<StudentEntity> _students = const [];
  Map<String, String> _classNames = const {};
  Map<String, String> _sectionNames = const {};
  ExamEntity? _exam;
  String _classId = '';
  String _sectionId = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      final exams = await sl<ExamRepository>().getExams();
      exams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _exams = exams;
        _exam = exams.isEmpty ? null : exams.first;
        _loading = exams.isNotEmpty;
      });
      if (_exam != null) {
        await _loadExam(_exam!);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$error';
        });
      }
    }
  }

  Future<void> _loadExam(ExamEntity exam) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        sl<StudentRepository>().getStudents(),
        sl<AcademicStructureRepository>().getClasses(),
        sl<AcademicStructureRepository>().getSections(),
        sl<StudentDevelopmentProfileRepository>().getForExam(exam.id),
      ]);
      final students = values[0] as List<StudentEntity>;
      final classes = values[1] as List<dynamic>;
      final sections = values[2] as List<dynamic>;
      final saved = values[3] as List<StudentDevelopmentProfileEntity>;
      final classNames = {
        for (final item in classes) item.id as String: item.name as String,
      };
      final sectionNames = {
        for (final item in sections) item.id as String: item.name as String,
      };
      students.removeWhere((item) => !item.isActive);
      students.sort((a, b) {
        final classOrder = (classNames[a.classId] ?? a.classId).compareTo(
          classNames[b.classId] ?? b.classId,
        );
        if (classOrder != 0) return classOrder;
        final sectionOrder = (sectionNames[a.sectionId] ?? a.sectionId)
            .compareTo(sectionNames[b.sectionId] ?? b.sectionId);
        if (sectionOrder != 0) return sectionOrder;
        return a.fullName.compareTo(b.fullName);
      });
      if (!mounted || _exam?.id != exam.id) return;
      setState(() {
        _students = students;
        _classNames = classNames;
        _sectionNames = sectionNames;
        _profiles
          ..clear()
          ..addEntries(saved.map((item) => MapEntry(item.studentId, item)));
        _classId = '';
        _sectionId = '';
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$error';
        });
      }
    }
  }

  List<StudentEntity> get _visible => _students
      .where(
        (result) =>
            (_classId.isEmpty || _classKey(result) == _classId) &&
            (_sectionId.isEmpty || _sectionKey(result) == _sectionId),
      )
      .toList();

  String _classKey(StudentEntity student) =>
      (_classNames[student.classId] ?? student.classId).trim().toLowerCase();

  String _sectionKey(StudentEntity student) =>
      (_sectionNames[student.sectionId] ?? student.sectionId)
          .trim()
          .toLowerCase();

  StudentDevelopmentProfileEntity _profileFor(StudentEntity student) =>
      _profiles[student.id] ??
      StudentDevelopmentProfileEntity(
        id: StudentDevelopmentProfileEntity.documentIdFor(
          _exam!.id,
          student.id,
        ),
        examId: _exam!.id,
        academicSession: _exam!.academicSession,
        studentId: student.id,
        classId: student.classId,
        sectionId: student.sectionId,
      );

  void _update(StudentEntity student, StudentDevelopmentProfileEntity value) {
    setState(() => _profiles[student.id] = value);
  }

  Future<void> _save() async {
    final visible = _visible;
    final completedStudents = visible
        .where((student) => _profileFor(student).isComplete)
        .toList(growable: false);
    if (completedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete ratings for at least one student before saving.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final actor = sl<AccessControlService>().currentUserEmail ?? '';
      final now = DateTime.now();
      final values = completedStudents
          .map((r) => _profileFor(r).copyWith(updatedBy: actor, updatedAt: now))
          .toList();
      await sl<StudentDevelopmentProfileRepository>().saveAll(values);
      if (!mounted) return;
      setState(() {
        for (final item in values) {
          _profiles[item.studentId] = item;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${values.length} development profile(s) saved. '
            'Incomplete students were skipped.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!sl<AccessControlService>().hasPermission(AppPermission.resultsEnter)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Student Development Profiles'),
          actions: const [DashboardNavigationButton()],
        ),
        body: const Center(
          child: Text(
            'Only authorized class teachers and result-entry staff can edit development profiles.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final classes = <String, String>{
      for (final student in _students)
        _classKey(student): (_classNames[student.classId] ?? student.classId)
            .trim(),
    };
    final sections = <String, String>{
      if (_classId.isNotEmpty)
        for (final student in _students.where(
          (student) => _classKey(student) == _classId,
        ))
          _sectionKey(student):
              (_sectionNames[student.sectionId] ?? student.sectionId).trim(),
    };
    final classEntries = classes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final sectionEntries = sections.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final visible = _visible;
    final complete = visible.where((r) => _profileFor(r).isComplete).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Development Profiles'),
        actions: const [DashboardNavigationButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 280,
                  child: DropdownButtonFormField<ExamEntity>(
                    initialValue: _exam,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Exam',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _exams
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              '${e.name} • ${e.academicSession}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _exam = value);
                        _loadExam(value);
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    initialValue: _classId,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('All classes'),
                      ),
                      ...classEntries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      _classId = value ?? '';
                      _sectionId = '';
                    }),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('section-$_classId'),
                    initialValue: _sectionId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      hintText: 'Select class first',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('All sections'),
                      ),
                      ...sectionEntries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      ),
                    ],
                    onChanged: _classId.isEmpty
                        ? null
                        : (value) => setState(() => _sectionId = value ?? ''),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _saving || visible.isEmpty ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text('Save ($complete/${visible.length})'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Rate each area from 1 (Needs Improvement) to 5 (Excellent). Punctuality is calculated automatically from attendance.',
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : visible.isEmpty
                  ? const Center(
                      child: Text(
                        'No active students found for this selection.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, index) => _DevelopmentRow(
                        student: visible[index],
                        className:
                            _classNames[visible[index].classId] ??
                            visible[index].classId,
                        sectionName:
                            _sectionNames[visible[index].sectionId] ??
                            visible[index].sectionId,
                        profile: _profileFor(visible[index]),
                        onChanged: (value) => _update(visible[index], value),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevelopmentRow extends StatelessWidget {
  const _DevelopmentRow({
    required this.student,
    required this.className,
    required this.sectionName,
    required this.profile,
    required this.onChanged,
  });
  final StudentEntity student;
  final String className;
  final String sectionName;
  final StudentDevelopmentProfileEntity profile;
  final ValueChanged<StudentDevelopmentProfileEntity> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 220,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 17,
              child: Text(
                student.fullName.trim().isEmpty
                    ? '?'
                    : student.fullName.trim()[0].toUpperCase(),
              ),
            ),
            title: Text(
              student.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '$className-$sectionName • Roll ${student.rollNumber}',
            ),
          ),
        ),
        _Rating(
          label: 'Discipline',
          value: profile.discipline,
          onChanged: (v) => onChanged(profile.copyWith(discipline: v)),
        ),
        _Rating(
          label: 'Communication',
          value: profile.communication,
          onChanged: (v) => onChanged(profile.copyWith(communication: v)),
        ),
        _Rating(
          label: 'Participation',
          value: profile.classParticipation,
          onChanged: (v) => onChanged(profile.copyWith(classParticipation: v)),
        ),
        _Rating(
          label: 'Homework',
          value: profile.homework,
          onChanged: (v) => onChanged(profile.copyWith(homework: v)),
        ),
        _Rating(
          label: 'Hygiene',
          value: profile.personalHygiene,
          onChanged: (v) => onChanged(profile.copyWith(personalHygiene: v)),
        ),
        const Chip(
          avatar: Icon(Icons.auto_awesome, size: 16),
          label: Text('Punctuality: Auto'),
        ),
      ],
    ),
  );
}

class _Rating extends StatelessWidget {
  const _Rating({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 142,
    child: DropdownButtonFormField<int>(
      initialValue: value == 0 ? null : value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: List.generate(
        5,
        (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}  ★')),
      ),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
}
