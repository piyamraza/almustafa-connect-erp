import 'dart:convert';

import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/entities/subject_component_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/repositories/subject_component_repository.dart';
import '../../../teachers/domain/entities/teacher_assignment_entity.dart';
import '../../../teachers/domain/repositories/teacher_assignment_repository.dart';
import '../entities/exam_date_sheet_entity.dart';
import '../entities/exam_date_sheet_generation_entity.dart';
import '../entities/exam_entity.dart';
import '../repositories/exam_date_sheet_repository.dart';
import 'validate_exam_date_sheet.dart';

class GenerateExamDateSheetOptions {
  const GenerateExamDateSheetOptions(
    this._academicRepository,
    this._assignmentRepository,
    this._dateSheetRepository,
    this._validator,
    this._componentRepository,
  );

  final AcademicStructureRepository _academicRepository;
  final TeacherAssignmentRepository _assignmentRepository;
  final ExamDateSheetRepository _dateSheetRepository;
  final ValidateExamDateSheet _validator;
  final SubjectComponentRepository _componentRepository;

  Future<List<ExamDateSheetGeneratedOption>> call({
    required ExamEntity exam,
    required ExamDateSheetGenerationRequest request,
  }) async {
    final dates = _availableDates(request);
    if (dates.isEmpty) {
      throw StateError('No available exam dates match the selected rules.');
    }

    final values = await Future.wait<Object?>([
      _academicRepository.getClasses(),
      _academicRepository.getSections(),
      _academicRepository.getSubjects(),
      _assignmentRepository.getAssignments(),
      _componentRepository.getComponents(),
    ]);

    final classes =
        (values[0] as List<AcademicClassEntity>)
            .where((item) => item.isActive)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final sections =
        (values[1] as List<SectionEntity>)
            .where((item) => item.isActive)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final subjects =
        (values[2] as List<AcademicSubjectEntity>)
            .where((item) => item.isActive)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final assignments = (values[3] as List<TeacherAssignmentEntity>)
        .where(
          (item) =>
              _normalise(item.academicSession) ==
              _normalise(exam.academicSession),
        )
        .toList(growable: false);

    final components = (values[4] as List<SubjectComponentEntity>)
        .where((item) => item.isActive)
        .toList(growable: false);

    final tasks = <_PaperTask>[];

    for (final academicClass in classes) {
      final classSections = sections
          .where((section) => section.classId == academicClass.id)
          .toList(growable: false);

      for (final section in classSections) {
        final classSubjects = _subjectsFor(
          subjects,
          academicClass.id,
          section.id,
        );

        for (final subject in classSubjects) {
          final assignment = _findAssignment(
            assignments,
            classId: academicClass.id,
            className: academicClass.name,
            sectionId: section.id,
            sectionName: section.name,
            subjectName: subject.name,
          );

          if (assignment == null) {
            continue;
          }

          final examSubjects = _expandForExamination(
            subject,
            components,
          );

          for (final examSubject in examSubjects) {
            tasks.add(
              _PaperTask(
                academicClass: academicClass,
                section: section,
                subject: examSubject,
                assignment: assignment,
              ),
            );
          }
        }
      }
    }

    if (tasks.isEmpty) {
      throw StateError(
        'No subject and teacher assignments are available for generation.',
      );
    }

    final strategies = <ExamDateSheetGenerationStrategy>[
      ExamDateSheetGenerationStrategy.balanced,
      ExamDateSheetGenerationStrategy.maximumGap,
      ExamDateSheetGenerationStrategy.compact,
    ];

    final options = <ExamDateSheetGeneratedOption>[];

    for (final strategy in strategies) {
      final papers = _generateForStrategy(
        exam: exam,
        request: request,
        dates: dates,
        tasks: tasks,
        strategy: strategy,
      );
      final validation = _validator(exam: exam, papers: papers);

      final ordered = List<ExamDateSheetPaperEntity>.of(papers)
        ..sort((a, b) {
          final date = a.examDate.compareTo(b.examDate);
          if (date != 0) return date;
          return a.className.compareTo(b.className);
        });

      options.add(
        ExamDateSheetGeneratedOption(
          label: _label(strategy),
          strategy: strategy,
          papers: ordered,
          validation: validation,
          startDate: ordered.isEmpty
              ? request.startDate
              : ordered.first.examDate,
          endDate: ordered.isEmpty ? request.endDate : ordered.last.examDate,
        ),
      );
    }

    options.sort((a, b) => b.score.compareTo(a.score));
    return List<ExamDateSheetGeneratedOption>.unmodifiable(options);
  }

  List<ExamDateSheetPaperEntity> _generateForStrategy({
    required ExamEntity exam,
    required ExamDateSheetGenerationRequest request,
    required List<DateTime> dates,
    required List<_PaperTask> tasks,
    required ExamDateSheetGenerationStrategy strategy,
  }) {
    final grouped = <String, List<_PaperTask>>{};
    for (final task in tasks) {
      final key = '${task.academicClass.id}|${task.section.id}';
      grouped.putIfAbsent(key, () => []).add(task);
    }

    final classDateUsage = <String>{};
    final teacherDateUsage = <String>{};
    final papers = <ExamDateSheetPaperEntity>[];

    var groupIndex = 0;

    for (final classTasks in grouped.values) {
      final orderedTasks = List<_PaperTask>.of(classTasks);
      _orderTasks(orderedTasks, strategy, groupIndex);

      for (var index = 0; index < orderedTasks.length; index++) {
        final task = orderedTasks[index];
        final dateOrder = _dateOrder(
          dates: dates,
          strategy: strategy,
          paperIndex: index,
          paperCount: orderedTasks.length,
          groupIndex: groupIndex,
        );

        DateTime? selectedDate;

        for (final date in dateOrder) {
          final dateKey = _dateKey(date);
          final classKey =
              '${task.academicClass.id}|${task.section.id}|$dateKey';
          final teacherKey = '${task.assignment.teacherId}|$dateKey';

          if (classDateUsage.contains(classKey) ||
              teacherDateUsage.contains(teacherKey)) {
            continue;
          }

          selectedDate = date;
          classDateUsage.add(classKey);
          teacherDateUsage.add(teacherKey);
          break;
        }

        if (selectedDate == null) {
          continue;
        }

        final totalMarks = exam.totalMarks > 0 ? exam.totalMarks : 100.0;
        final passingMarks = exam.passingMarks >= 0
            ? exam.passingMarks
            : totalMarks * 0.4;

        papers.add(
          ExamDateSheetPaperEntity(
            id: _dateSheetRepository.generatePaperId(),
            classId: task.academicClass.id,
            className: task.academicClass.name,
            sectionId: task.section.id,
            sectionName: task.section.name,
            subjectId: task.subject.id,
            subjectName: task.subject.name,
            teacherId: task.assignment.teacherId,
            teacherName: task.assignment.teacherName,
            examDate: selectedDate,
            startMinutes: request.startMinutes,
            endMinutes: request.startMinutes + request.paperDurationMinutes,
            totalMarks: totalMarks,
            passingMarks: passingMarks,
            instructions: '',
          ),
        );
      }

      groupIndex++;
    }

    return papers;
  }

  List<DateTime> _dateOrder({
    required List<DateTime> dates,
    required ExamDateSheetGenerationStrategy strategy,
    required int paperIndex,
    required int paperCount,
    required int groupIndex,
  }) {
    if (strategy == ExamDateSheetGenerationStrategy.compact) {
      return List<DateTime>.of(dates);
    }

    if (strategy == ExamDateSheetGenerationStrategy.maximumGap) {
      final values = <DateTime>[];
      if (paperCount <= 1) return List<DateTime>.of(dates);

      final target = ((paperIndex * (dates.length - 1)) / (paperCount - 1))
          .round();
      for (var distance = 0; distance < dates.length; distance++) {
        final right = target + distance;
        final left = target - distance;
        if (right < dates.length) values.add(dates[right]);
        if (left >= 0 && left != right) values.add(dates[left]);
      }
      return values;
    }

    final offset = groupIndex % dates.length;
    return [
      for (var index = 0; index < dates.length; index++)
        dates[(index + offset) % dates.length],
    ];
  }

  void _orderTasks(
    List<_PaperTask> tasks,
    ExamDateSheetGenerationStrategy strategy,
    int seed,
  ) {
    tasks.sort((a, b) => a.subject.name.compareTo(b.subject.name));

    if (strategy == ExamDateSheetGenerationStrategy.balanced) {
      final difficult = tasks.where((item) => _isDifficult(item.subject.name));
      final normal = tasks.where((item) => !_isDifficult(item.subject.name));
      final result = <_PaperTask>[];
      final difficultList = difficult.toList();
      final normalList = normal.toList();

      while (difficultList.isNotEmpty || normalList.isNotEmpty) {
        if (difficultList.isNotEmpty) result.add(difficultList.removeAt(0));
        if (normalList.isNotEmpty) result.add(normalList.removeAt(0));
      }

      tasks
        ..clear()
        ..addAll(result);
    } else if (strategy == ExamDateSheetGenerationStrategy.maximumGap) {
      tasks.sort((a, b) {
        final difficultCompare = _isDifficult(
          b.subject.name,
        ).toString().compareTo(_isDifficult(a.subject.name).toString());
        if (difficultCompare != 0) return difficultCompare;
        return a.subject.name.compareTo(b.subject.name);
      });
    } else if (seed.isOdd) {
      tasks.setAll(0, tasks.reversed);
    }
  }

  List<DateTime> _availableDates(ExamDateSheetGenerationRequest request) {
    final holidays = request.holidays.map(_dateKey).toSet();
    final values = <DateTime>[];
    var current = _dateOnly(request.startDate);
    final end = _dateOnly(request.endDate);

    while (!current.isAfter(end)) {
      if (request.allowedWeekdays.contains(current.weekday) &&
          !holidays.contains(_dateKey(current))) {
        values.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    return values;
  }

  List<AcademicSubjectEntity> _expandForExamination(
    AcademicSubjectEntity subject,
    List<SubjectComponentEntity> components,
  ) {
    if (!subject.useComponentsInExamination) {
      return [subject];
    }

    final active = components
        .where(
          (component) =>
              component.isActive &&
              component.parentSubjectId == subject.id,
        )
        .toList()
      ..sort(
        (first, second) =>
            first.displayOrder.compareTo(second.displayOrder),
      );

    if (active.isEmpty) {
      return [subject];
    }

    return active
        .map(
          (component) => subject.copyWith(
            id: _componentSubjectId(subject, component),
            name: _componentDisplayName(
              subject.name,
              component.componentName,
            ),
          ),
        )
        .toList(growable: false);
  }

  String _componentSubjectId(
    AcademicSubjectEntity parent,
    SubjectComponentEntity component,
  ) {
    final encodedParent = base64Url
        .encode(utf8.encode(parent.name))
        .replaceAll('=', '');
    final reportFlag = parent.useComponentsInReportCard ? '1' : '0';

    return 'cmp::${parent.id}::$encodedParent::$reportFlag::${component.id}';
  }

  String _componentDisplayName(
    String parentName,
    String componentName,
  ) {
    final parent = parentName.trim();
    final component = componentName.trim();

    if (parent.isEmpty) return component;
    if (component.isEmpty) return parent;

    final normalizedParent = _normalise(parent);
    final normalizedComponent = _normalise(component);

    if (normalizedComponent == normalizedParent ||
        normalizedComponent.startsWith('$normalizedParent ')) {
      return component;
    }

    return '$parent $component';
  }
  List<AcademicSubjectEntity> _subjectsFor(
    List<AcademicSubjectEntity> subjects,
    String classId,
    String sectionId,
  ) {
    final byName = <String, AcademicSubjectEntity>{};

    for (final subject in subjects) {
      if (subject.classId == classId && subject.sectionId == null) {
        byName[_normalise(subject.name)] = subject;
      }
    }
    for (final subject in subjects) {
      if (subject.classId == classId && subject.sectionId == sectionId) {
        byName[_normalise(subject.name)] = subject;
      }
    }

    return byName.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  TeacherAssignmentEntity? _findAssignment(
    List<TeacherAssignmentEntity> assignments, {
    required String classId,
    required String className,
    required String sectionId,
    required String sectionName,
    required String subjectName,
  }) {
    for (final assignment in assignments) {
      final classMatches =
          assignment.classId == classId ||
          _normalise(assignment.classId) == _normalise(className);
      final sectionMatches =
          assignment.sectionId == sectionId ||
          _normalise(assignment.sectionId) == _normalise(sectionName);
      final subjectMatches =
          _normalise(assignment.subject) == _normalise(subjectName);

      if (classMatches && sectionMatches && subjectMatches) {
        return assignment;
      }
    }
    return null;
  }

  bool _isDifficult(String value) {
    final subject = value.toLowerCase();
    return subject.contains('math') ||
        subject.contains('science') ||
        subject.contains('computer') ||
        subject.contains('physics') ||
        subject.contains('chemistry') ||
        subject.contains('biology');
  }

  String _label(ExamDateSheetGenerationStrategy strategy) => switch (strategy) {
    ExamDateSheetGenerationStrategy.balanced => 'Balanced Schedule',
    ExamDateSheetGenerationStrategy.maximumGap => 'Maximum Gap Schedule',
    ExamDateSheetGenerationStrategy.compact => 'Compact Schedule',
  };

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dateKey(DateTime value) =>
      '${value.year}-${value.month}-${value.day}';

  String _normalise(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

class _PaperTask {
  const _PaperTask({
    required this.academicClass,
    required this.section,
    required this.subject,
    required this.assignment,
  });

  final AcademicClassEntity academicClass;
  final SectionEntity section;
  final AcademicSubjectEntity subject;
  final TeacherAssignmentEntity assignment;
}
