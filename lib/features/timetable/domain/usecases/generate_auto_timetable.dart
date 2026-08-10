import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../teachers/domain/entities/teacher_assignment_entity.dart';
import '../../../teachers/domain/repositories/teacher_assignment_repository.dart';
import '../entities/auto_timetable_generation_entity.dart';
import '../entities/class_timetable_entry_entity.dart';
import '../entities/timetable_configuration_entity.dart';
import '../repositories/timetable_repository.dart';

class GenerateAutoTimetable {
  const GenerateAutoTimetable(
    this._timetableRepository,
    this._academicRepository,
    this._assignmentRepository,
  );

  final TimetableRepository _timetableRepository;
  final AcademicStructureRepository _academicRepository;
  final TeacherAssignmentRepository _assignmentRepository;

  Future<AutoTimetableGenerationResult> preview(
    AutoTimetableGenerationRequest request,
  ) async {
    final branchId = request.branchId.trim();
    final session = request.academicSession.trim();

    if (branchId.isEmpty || session.isEmpty) {
      throw ArgumentError('Branch and academic session are required.');
    }

    final values = await Future.wait<Object?>([
      _timetableRepository.getConfigurations(
        branchId: branchId,
        academicSession: session,
      ),
      _timetableRepository.getAllTimetableEntries(
        branchId: branchId,
        academicSession: session,
      ),
      _academicRepository.getClasses(),
      _academicRepository.getSections(),
      _academicRepository.getSubjects(),
      _assignmentRepository.getAssignments(),
    ]);

    final configurations =
        values[0] as List<TimetableConfigurationEntity>;
    if (configurations.isEmpty) {
      throw StateError('Timetable configuration was not found.');
    }

    final existing = values[1] as List<ClassTimetableEntryEntity>;
    final classes = (values[2] as dynamic)
        .where((item) => item.isActive)
        .toList();
    final sections = (values[3] as dynamic)
        .where((item) => item.isActive)
        .toList();
    final subjects = (values[4] as List<AcademicSubjectEntity>)
        .where((item) => item.isActive)
        .toList();
    final assignments = (values[5] as List<TeacherAssignmentEntity>)
        .where(
          (item) => _normalise(item.academicSession) == _normalise(session),
        )
        .toList();

    final occupiedClassSlots = <String>{};
    final occupiedTeacherSlots = <String>{};
    final teacherBusyTimes = <String, List<_TimeRange>>{};
    final periodSlotById = <String, String>{
      for (final configuration in configurations)
        for (final period in configuration.periods)
          period.id: '${period.startMinutes}-${period.endMinutes}',
    };

    if (!request.replaceExisting) {
      for (final entry in existing) {
        occupiedClassSlots.add(
          '${entry.classId}|${entry.sectionId}|${entry.weekday}|${entry.periodId}',
        );
        final timeSlot = periodSlotById[entry.periodId] ?? entry.periodId;
        occupiedTeacherSlots.add(
          '${entry.teacherId}|${entry.weekday}|$timeSlot',
        );
        dynamic period;
        for (final configuration in configurations) {
          for (final candidate in configuration.periods) {
            if (candidate.id == entry.periodId) {
              period = candidate;
              break;
            }
          }
          if (period != null) break;
        }
        if (period != null) {
          teacherBusyTimes
              .putIfAbsent(
                '${entry.teacherId}|${entry.weekday}',
                () => <_TimeRange>[],
              )
              .add(_TimeRange(period.startMinutes, period.endMinutes));
        }
      }
    }

    final generated = <ClassTimetableEntryEntity>[];
    final warnings = <String>[];
    var classSectionCount = 0;
    var totalAvailableSlots = 0;

    for (final academicClass in classes) {
      TimetableConfigurationEntity? configuration;
      for (final candidate in configurations) {
        if (candidate.classIds.contains(academicClass.id)) {
          configuration = candidate;
          break;
        }
      }
      if (configuration == null) {
        for (final candidate in configurations) {
          if (candidate.classIds.isEmpty) {
            configuration = candidate;
            break;
          }
        }
      }
      if (configuration == null) {
        warnings.add(
          '${academicClass.name}: No default or class-specific schedule found.',
        );
        continue;
      }
      final days = configuration.workingDays.toList()..sort();
      final periods = configuration.orderedPeriods
          .where((period) => period.isTeaching)
          .toList(growable: false);
      if (days.isEmpty || periods.isEmpty) {
        warnings.add(
          '${academicClass.name}: Schedule has no working days or teaching periods.',
        );
        continue;
      }
      final classSections = sections
          .where((section) => section.classId == academicClass.id)
          .toList();

      for (final section in classSections) {
        classSectionCount++;
        totalAvailableSlots += days.length * periods.length;

        final availableSubjects = _subjectsFor(
          subjects,
          academicClass.id,
          section.id,
        );

        final subjectAssignments = <_SubjectAssignment>[];
        for (final subject in availableSubjects) {
          final assignment = _findAssignment(
            assignments,
            classId: academicClass.id,
            className: academicClass.name,
            sectionId: section.id,
            sectionName: section.name,
            subjectName: subject.name,
          );

          if (assignment == null) {
            warnings.add(
              '${academicClass.name} - ${section.name}: '
              'No teacher assigned for ${subject.name}.',
            );
            continue;
          }

          subjectAssignments.add(
            _SubjectAssignment(subject: subject, assignment: assignment),
          );
        }

        if (subjectAssignments.isEmpty) {
          warnings.add(
            '${academicClass.name} - ${section.name}: '
            'No schedulable subject assignments.',
          );
          continue;
        }

        var subjectCursor = 0;

        for (final day in days) {
          final usedToday = <String, int>{};

          for (final period in periods) {
            final timeSlot = '${period.startMinutes}-${period.endMinutes}';
            final classSlot =
                '${academicClass.id}|${section.id}|$day|${period.id}';
            if (occupiedClassSlots.contains(classSlot)) {
              continue;
            }

            _SubjectAssignment? selected;
            for (
              var attempt = 0;
              attempt < subjectAssignments.length;
              attempt++
            ) {
              final index =
                  (subjectCursor + attempt) % subjectAssignments.length;
              final candidate = subjectAssignments[index];
              final teacherSlot =
                  '${candidate.assignment.teacherId}|$day|$timeSlot';

              if (occupiedTeacherSlots.contains(teacherSlot) ||
                  _teacherIsBusy(
                    teacherBusyTimes,
                    candidate.assignment.teacherId,
                    day,
                    period.startMinutes,
                    period.endMinutes,
                  )) {
                continue;
              }

              final dailyCount = usedToday[candidate.subject.id] ?? 0;
              if (dailyCount > 0 && subjectAssignments.length > 1) {
                continue;
              }

              selected = candidate;
              subjectCursor = (index + 1) % subjectAssignments.length;
              break;
            }

            selected ??= _firstAvailable(
              subjectAssignments,
              occupiedTeacherSlots,
              teacherBusyTimes,
              day,
              timeSlot,
              period.startMinutes,
              period.endMinutes,
              subjectCursor,
            );

            if (selected == null) {
              warnings.add(
                '${academicClass.name} - ${section.name}, '
                '${_dayName(day)} ${period.label}: '
                'No conflict-free teacher available.',
              );
              continue;
            }

            final teacherSlot =
                '${selected.assignment.teacherId}|$day|$timeSlot';
            final now = DateTime.now();

            final entry = ClassTimetableEntryEntity(
              id: _timetableRepository.generateClassTimetableEntryId(),
              branchId: branchId,
              academicSession: session,
              classId: academicClass.id,
              className: academicClass.name,
              sectionId: section.id,
              sectionName: section.name,
              weekday: day,
              periodId: period.id,
              periodLabel: period.label,
              periodOrder: period.order,
              subjectId: selected.subject.id,
              subjectName: selected.subject.name,
              teacherId: selected.assignment.teacherId,
              teacherName: selected.assignment.teacherName,
              createdAt: now,
              updatedAt: now,
            );

            generated.add(entry);
            occupiedClassSlots.add(classSlot);
            occupiedTeacherSlots.add(teacherSlot);
            teacherBusyTimes
                .putIfAbsent(
                  '${selected.assignment.teacherId}|$day',
                  () => <_TimeRange>[],
                )
                .add(_TimeRange(period.startMinutes, period.endMinutes));
            usedToday[selected.subject.id] =
                (usedToday[selected.subject.id] ?? 0) + 1;
          }
        }
      }
    }

    return AutoTimetableGenerationResult(
      generatedEntries: generated,
      warnings: warnings,
      totalClassSections: classSectionCount,
      totalAvailableSlots: totalAvailableSlots,
      preservedEntries: request.replaceExisting ? 0 : existing.length,
    );
  }

  Future<void> save(
    AutoTimetableGenerationRequest request,
    AutoTimetableGenerationResult result,
  ) async {
    if (request.replaceExisting) {
      final existing = await _timetableRepository.getAllTimetableEntries(
        branchId: request.branchId,
        academicSession: request.academicSession,
      );
      for (final entry in existing) {
        await _timetableRepository.deleteClassTimetableEntry(entry.id);
      }
    }

    for (final entry in result.generatedEntries) {
      await _timetableRepository.saveClassTimetableEntry(entry);
    }
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

    final values = byName.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return values;
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

  _SubjectAssignment? _firstAvailable(
    List<_SubjectAssignment> values,
    Set<String> occupiedTeacherSlots,
    Map<String, List<_TimeRange>> teacherBusyTimes,
    int day,
    String timeSlot,
    int startMinutes,
    int endMinutes,
    int start,
  ) {
    for (var attempt = 0; attempt < values.length; attempt++) {
      final candidate = values[(start + attempt) % values.length];
      final key = '${candidate.assignment.teacherId}|$day|$timeSlot';
      if (!occupiedTeacherSlots.contains(key) &&
          !_teacherIsBusy(
            teacherBusyTimes,
            candidate.assignment.teacherId,
            day,
            startMinutes,
            endMinutes,
          )) {
        return candidate;
      }
    }
    return null;
  }

  bool _teacherIsBusy(
    Map<String, List<_TimeRange>> busyTimes,
    String teacherId,
    int day,
    int startMinutes,
    int endMinutes,
  ) => busyTimes['$teacherId|$day']?.any(
    (range) => startMinutes < range.end && endMinutes > range.start,
  ) ?? false;

  String _normalise(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  String _dayName(int value) => switch (value) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    DateTime.sunday => 'Sunday',
    _ => 'Day',
  };
}

class _SubjectAssignment {
  const _SubjectAssignment({required this.subject, required this.assignment});

  final AcademicSubjectEntity subject;
  final TeacherAssignmentEntity assignment;
}

class _TimeRange {
  const _TimeRange(this.start, this.end);

  final int start;
  final int end;
}
