import '../entities/academic_calendar_conflict_entity.dart';
import '../entities/academic_calendar_event_entity.dart';
import '../entities/academic_year_config_entity.dart';
import '../repositories/academic_calendar_repository.dart';
import '../repositories/academic_year_config_repository.dart';

class ValidateAcademicCalendar {
  const ValidateAcademicCalendar(
    this._calendarRepository,
    this._configRepository,
  );

  final AcademicCalendarRepository _calendarRepository;
  final AcademicYearConfigRepository _configRepository;

  Future<AcademicCalendarValidationResult> call(String academicSession) async {
    final config = await _configRepository.getBySession(academicSession);
    if (config == null) {
      return AcademicCalendarValidationResult(
        totalChecks: 1,
        conflicts: [
          AcademicCalendarConflictEntity(
            id: 'missing-config-$academicSession',
            severity: AcademicCalendarConflictSeverity.error,
            module: AcademicCalendarConflictModule.calendar,
            title: 'Academic Year Configuration Missing',
            description:
                'No Academic Year Wizard configuration exists for '
                '$academicSession.',
            suggestedResolution:
                'Open Academic Year Wizard and save the session setup.',
            affectedRecordId: null,
            affectedDate: null,
          ),
        ],
      );
    }

    final events = await _calendarRepository.getEvents(
      academicSession: academicSession,
      startDate: config.startDate,
      endDate: config.endDate,
    );

    final conflicts = <AcademicCalendarConflictEntity>[];
    var checks = 0;

    checks += _validateSessionBoundaries(config, events, conflicts);
    checks += _validateInvalidEventRanges(events, conflicts);
    checks += _validateDuplicateEvents(events, conflicts);
    checks += _validateEventOverlaps(events, conflicts);
    checks += _validateVacations(config, conflicts);
    checks += _validateExamWindows(config, conflicts);
    checks += _validateExamVacationConflicts(config, conflicts);
    checks += _validateEventWorkingDays(config, events, conflicts);
    checks += _validateFeeSchedule(config, events, conflicts);
    checks += _validateRules(config, conflicts);

    conflicts.sort((a, b) {
      final severity = _severityWeight(
        b.severity,
      ).compareTo(_severityWeight(a.severity));
      if (severity != 0) return severity;
      final dateA = a.affectedDate ?? DateTime(2100);
      final dateB = b.affectedDate ?? DateTime(2100);
      return dateA.compareTo(dateB);
    });

    return AcademicCalendarValidationResult(
      conflicts: conflicts,
      totalChecks: checks,
    );
  }

  int _validateSessionBoundaries(
    AcademicYearConfigEntity config,
    List<AcademicCalendarEventEntity> events,
    List<AcademicCalendarConflictEntity> conflicts,
  ) {
    var checks = 0;

    for (final event in events) {
      checks++;
      if (event.startDate.isBefore(config.startDate) ||
          event.endDate.isAfter(config.endDate)) {
        conflicts.add(
          AcademicCalendarConflictEntity(
            id: 'outside-session-${event.id}',
            severity: AcademicCalendarConflictSeverity.error,
            module: AcademicCalendarConflictModule.calendar,
            title: 'Event Outside Academic Session',
            description:
                '"${event.title}" is outside the configured session '
                'dates.',
            suggestedResolution:
                'Move the event inside the academic session or update '
                'the session dates.',
            affectedRecordId: event.id,
            affectedDate: event.startDate,
          ),
        );
      }
    }

    return checks;
  }

  int _validateInvalidEventRanges(
    List<AcademicCalendarEventEntity> events,
    List<AcademicCalendarConflictEntity> conflicts,
  ) {
    var checks = 0;

    for (final event in events) {
      checks++;
      if (event.endDate.isBefore(event.startDate)) {
        conflicts.add(
          AcademicCalendarConflictEntity(
            id: 'invalid-range-${event.id}',
            severity: AcademicCalendarConflictSeverity.error,
            module: AcademicCalendarConflictModule.calendar,
            title: 'Invalid Event Date Range',
            description: '"${event.title}" ends before its start date.',
            suggestedResolution: 'Correct the event start and end dates.',
            affectedRecordId: event.id,
            affectedDate: event.startDate,
          ),
        );
      }

      if (!event.isAllDay &&
          (event.startMinutes == null ||
              event.endMinutes == null ||
              event.startMinutes! >= event.endMinutes!)) {
        conflicts.add(
          AcademicCalendarConflictEntity(
            id: 'invalid-time-${event.id}',
            severity: AcademicCalendarConflictSeverity.error,
            module: AcademicCalendarConflictModule.calendar,
            title: 'Invalid Event Time',
            description: '"${event.title}" has an invalid start/end time.',
            suggestedResolution: 'Set an end time later than the start time.',
            affectedRecordId: event.id,
            affectedDate: event.startDate,
          ),
        );
      }
    }

    return checks;
  }

  int _validateDuplicateEvents(
    List<AcademicCalendarEventEntity> events,
    List<AcademicCalendarConflictEntity> conflicts,
  ) {
    var checks = 0;

    for (var first = 0; first < events.length; first++) {
      for (var second = first + 1; second < events.length; second++) {
        checks++;
        final a = events[first];
        final b = events[second];

        if (a.title.trim().toLowerCase() == b.title.trim().toLowerCase() &&
            _sameDay(a.startDate, b.startDate) &&
            _sameDay(a.endDate, b.endDate) &&
            a.type == b.type) {
          conflicts.add(
            AcademicCalendarConflictEntity(
              id: 'duplicate-${a.id}-${b.id}',
              severity: AcademicCalendarConflictSeverity.warning,
              module: AcademicCalendarConflictModule.calendar,
              title: 'Possible Duplicate Event',
              description:
                  '"${a.title}" appears more than once on the same '
                  'date range.',
              suggestedResolution:
                  'Review both records and delete the duplicate.',
              affectedRecordId: b.id,
              affectedDate: b.startDate,
            ),
          );
        }
      }
    }

    return checks;
  }

  int _validateEventOverlaps(
    List<AcademicCalendarEventEntity> events,
    List<AcademicCalendarConflictEntity> conflicts,
  ) {
    var checks = 0;

    for (var first = 0; first < events.length; first++) {
      for (var second = first + 1; second < events.length; second++) {
        checks++;
        final a = events[first];
        final b = events[second];

        if (!_overlaps(a.startDate, a.endDate, b.startDate, b.endDate)) {
          continue;
        }

        if (a.type == AcademicCalendarEventType.vacation &&
            b.type == AcademicCalendarEventType.vacation) {
          conflicts.add(
            AcademicCalendarConflictEntity(
              id: 'vacation-overlap-${a.id}-${b.id}',
              severity: AcademicCalendarConflictSeverity.error,
              module: AcademicCalendarConflictModule.calendar,
              title: 'Overlapping Vacation Events',
              description: '"${a.title}" overlaps with "${b.title}".',
              suggestedResolution:
                  'Merge the vacation ranges or correct their dates.',
              affectedRecordId: b.id,
              affectedDate: b.startDate,
            ),
          );
        }

        if (a.type == AcademicCalendarEventType.exam &&
                b.type == AcademicCalendarEventType.schoolActivity ||
            b.type == AcademicCalendarEventType.exam &&
                a.type == AcademicCalendarEventType.schoolActivity) {
          conflicts.add(
            AcademicCalendarConflictEntity(
              id: 'exam-activity-${a.id}-${b.id}',
              severity: AcademicCalendarConflictSeverity.warning,
              module: AcademicCalendarConflictModule.exams,
              title: 'Exam and School Activity Overlap',
              description: '"${a.title}" overlaps with "${b.title}".',
              suggestedResolution: 'Move the activity outside the exam window.',
              affectedRecordId: b.id,
              affectedDate: b.startDate,
            ),
          );
        }

        if (a.type == AcademicCalendarEventType.exam &&
                b.type == AcademicCalendarEventType.holiday ||
            b.type == AcademicCalendarEventType.exam &&
                a.type == AcademicCalendarEventType.holiday) {
          conflicts.add(
            AcademicCalendarConflictEntity(
              id: 'exam-holiday-${a.id}-${b.id}',
              severity: AcademicCalendarConflictSeverity.error,
              module: AcademicCalendarConflictModule.exams,
              title: 'Exam on Holiday',
              description: '"${a.title}" conflicts with "${b.title}".',
              suggestedResolution: 'Move the exam or change the holiday dates.',
              affectedRecordId: a.type == AcademicCalendarEventType.exam
                  ? a.id
                  : b.id,
              affectedDate: a.startDate,
            ),
          );
        }
      }
    }

    return checks;
  }

  int _validateVacations(
    AcademicYearConfigEntity config,
    List<AcademicCalendarConflictEntity> conflicts,
  ) {
    var checks = 0;

    for (final vacation in config.vacations) {
      checks++;
      if (vacation.endDate.isBefore(vacation.startDate)) {
        conflicts.add(
          AcademicCalendarConflictEntity(
            id: 'invalid-vacation-${vacation.id}',
            severity: AcademicCalendarConflictSeverity.error,
            module: AcademicCalendarConflictModule.calendar,
            title: 'Invalid Vacation Range',
            description: '"${vacation.title}" ends before it starts.',
            suggestedResolution: 'Correct the vacation start and end dates.',
            affectedRecordId: vacation.id,
            affectedDate: vacation.startDate,
          ),
        );
      }

      if (vacation.startDate.isBefore(config.startDate) ||
          vacation.endDate.isAfter(config.endDate)) {
        conflicts.add(
          AcademicCalendarConflictEntity(
            id: 'vacation-outside-${vacation.id}',
            severity: AcademicCalendarConflictSeverity.warning,
            module: AcademicCalendarConflictModule.calendar,
            title: 'Vacation Outside Session',
            description:
                '"${vacation.title}" is partly outside the academic '
                'session.',
            suggestedResolution: 'Adjust the vacation or session dates.',
            affectedRecordId: vacation.id,
            affectedDate: vacation.startDate,
          ),
        );
      }
    }

    for (var first = 0; first < config.vacations.length; first++) {
      for (var second = first + 1; second < config.vacations.length; second++) {
        checks++;
        final a = config.vacations[first];
        final b = config.vacations[second];

        if (_overlaps(a.startDate, a.endDate, b.startDate, b.endDate)) {
          conflicts.add(
            AcademicCalendarConflictEntity(
              id: 'wizard-vacation-overlap-${a.id}-${b.id}',
              severity: AcademicCalendarConflictSeverity.error,
              module: AcademicCalendarConflictModule.calendar,
              title: 'Overlapping Wizard Vacations',
              description: '"${a.title}" overlaps with "${b.title}".',
              suggestedResolution:
                  'Edit the Academic Year Wizard vacation ranges.',
              affectedRecordId: b.id,
              affectedDate: b.startDate,
            ),
          );
        }
      }
    }

    return checks;
  }

  int _validateExamWindows(
    AcademicYearConfigEntity config,
    List<AcademicCalendarConflictEntity> conflicts,
  ) {
    var checks = 0;

    for (final exam in config.examWindows) {
      checks++;
      if (exam.endDate.isBefore(exam.startDate)) {
        conflicts.add(
          AcademicCalendarConflictEntity(
            id: 'invalid-exam-window-${exam.id}',
            severity: AcademicCalendarConflictSeverity.error,
            module: AcademicCalendarConflictModule.exams,
            title: 'Invalid Exam Window',
            description: '"${exam.title}" ends before it starts.',
            suggestedResolution: 'Correct the exam window dates.',
            affectedRecordId: exam.id,
            affectedDate: exam.startDate,
          ),
        );
      }
    }

    for (var first = 0; first < config.examWindows.length; first++) {
      for (
        var second = first + 1;
        second < config.examWindows.length;
        second++
      ) {
        checks++;
        final a = config.examWindows[first];
        final b = config.examWindows[second];

        if (_overlaps(a.startDate, a.endDate, b.startDate, b.endDate)) {
          conflicts.add(
            AcademicCalendarConflictEntity(
              id: 'exam-window-overlap-${a.id}-${b.id}',
              severity: AcademicCalendarConflictSeverity.warning,
              module: AcademicCalendarConflictModule.exams,
              title: 'Overlapping Exam Windows',
              description: '"${a.title}" overlaps with "${b.title}".',
              suggestedResolution:
                  'Review whether both exam windows should overlap.',
              affectedRecordId: b.id,
              affectedDate: b.startDate,
            ),
          );
        }
      }
    }

    return checks;
  }

  int _validateExamVacationConflicts(
    AcademicYearConfigEntity config,
    List<AcademicCalendarConflictEntity> conflicts,
  ) {
    var checks = 0;

    for (final exam in config.examWindows) {
      for (final vacation in config.vacations) {
        checks++;
        if (_overlaps(
          exam.startDate,
          exam.endDate,
          vacation.startDate,
          vacation.endDate,
        )) {
          conflicts.add(
            AcademicCalendarConflictEntity(
              id: 'exam-vacation-${exam.id}-${vacation.id}',
              severity: AcademicCalendarConflictSeverity.error,
              module: AcademicCalendarConflictModule.exams,
              title: 'Exam Window During Vacation',
              description: '"${exam.title}" overlaps with "${vacation.title}".',
              suggestedResolution: 'Move the exam window outside the vacation.',
              affectedRecordId: exam.id,
              affectedDate: exam.startDate,
            ),
          );
        }
      }
    }

    return checks;
  }

  int _validateEventWorkingDays(
    AcademicYearConfigEntity config,
    List<AcademicCalendarEventEntity> events,
    List<AcademicCalendarConflictEntity> conflicts,
  ) {
    var checks = 0;

    for (final event in events) {
      checks++;
      final weekdayIsWorking = config.workingWeekdays.contains(
        event.startDate.weekday,
      );

      if (!weekdayIsWorking &&
          event.type != AcademicCalendarEventType.holiday &&
          event.type != AcademicCalendarEventType.vacation) {
        conflicts.add(
          AcademicCalendarConflictEntity(
            id: 'non-working-${event.id}',
            severity: AcademicCalendarConflictSeverity.warning,
            module: _moduleForEvent(event.type),
            title: 'Event on Non-working Day',
            description:
                '"${event.title}" starts on ${_weekday(event.startDate.weekday)}, '
                'which is not configured as a working day.',
            suggestedResolution:
                'Move the event or update the working-day rules.',
            affectedRecordId: event.id,
            affectedDate: event.startDate,
          ),
        );
      }

      if (config.isVacationDate(event.startDate) &&
          event.type != AcademicCalendarEventType.vacation) {
        conflicts.add(
          AcademicCalendarConflictEntity(
            id: 'during-vacation-${event.id}',
            severity: event.type == AcademicCalendarEventType.exam
                ? AcademicCalendarConflictSeverity.error
                : AcademicCalendarConflictSeverity.warning,
            module: _moduleForEvent(event.type),
            title: 'Event During Vacation',
            description:
                '"${event.title}" occurs during a configured vacation.',
            suggestedResolution: 'Move the event outside the vacation period.',
            affectedRecordId: event.id,
            affectedDate: event.startDate,
          ),
        );
      }
    }

    return checks;
  }

  int _validateFeeSchedule(
    AcademicYearConfigEntity config,
    List<AcademicCalendarEventEntity> events,
    List<AcademicCalendarConflictEntity> conflicts,
  ) {
    var checks = 0;
    var month = DateTime(config.startDate.year, config.startDate.month);

    while (!month.isAfter(
      DateTime(config.endDate.year, config.endDate.month),
    )) {
      final generationDate = DateTime(
        month.year,
        month.month,
        config.feeGenerationDay,
      );
      final dueDate = DateTime(month.year, month.month, config.feeDueDay);

      for (final entry in [
        ('Fee generation', generationDate),
        ('Fee due date', dueDate),
      ]) {
        checks++;
        final label = entry.$1;
        final date = entry.$2;

        final holiday = events.any(
          (event) =>
              (event.type == AcademicCalendarEventType.holiday ||
                  event.type == AcademicCalendarEventType.vacation) &&
              event.occursOn(date),
        );

        if (holiday || !config.workingWeekdays.contains(date.weekday)) {
          conflicts.add(
            AcademicCalendarConflictEntity(
              id: 'fee-${label.hashCode}-${date.millisecondsSinceEpoch}',
              severity: AcademicCalendarConflictSeverity.warning,
              module: AcademicCalendarConflictModule.fees,
              title: '$label on Non-working Day',
              description:
                  '$label for ${date.month}/${date.year} falls on '
                  '${_weekday(date.weekday)} or a holiday.',
              suggestedResolution:
                  'Use the next working day when generating the monthly '
                  'fee schedule.',
              affectedRecordId: null,
              affectedDate: date,
            ),
          );
        }
      }

      month = DateTime(month.year, month.month + 1);
    }

    return checks;
  }

  int _validateRules(
    AcademicYearConfigEntity config,
    List<AcademicCalendarConflictEntity> conflicts,
  ) {
    var checks = 3;

    if (config.workingWeekdays.contains(DateTime.saturday) &&
        !config.saturdayTimetableAllowed) {
      conflicts.add(
        const AcademicCalendarConflictEntity(
          id: 'saturday-rule',
          severity: AcademicCalendarConflictSeverity.warning,
          module: AcademicCalendarConflictModule.timetable,
          title: 'Saturday Rule Mismatch',
          description:
              'Saturday is a working day but Saturday timetable is '
              'disabled.',
          suggestedResolution:
              'Enable Saturday timetable or remove Saturday from working '
              'days.',
          affectedRecordId: null,
          affectedDate: null,
        ),
      );
    }

    if (config.homeworkAllowedWeekdays
        .difference(config.workingWeekdays)
        .isNotEmpty) {
      conflicts.add(
        const AcademicCalendarConflictEntity(
          id: 'homework-weekday-rule',
          severity: AcademicCalendarConflictSeverity.info,
          module: AcademicCalendarConflictModule.homework,
          title: 'Homework Allowed on Non-working Days',
          description:
              'Homework rules include weekdays that are not school '
              'working days.',
          suggestedResolution:
              'Review homework weekdays or allow this intentionally.',
          affectedRecordId: null,
          affectedDate: null,
        ),
      );
    }

    if (config.zeroPeriodAllowed) {
      conflicts.add(
        const AcademicCalendarConflictEntity(
          id: 'zero-period-info',
          severity: AcademicCalendarConflictSeverity.info,
          module: AcademicCalendarConflictModule.timetable,
          title: 'Zero Period Enabled',
          description:
              'Timetable integration must allow a zero period before '
              'regular periods.',
          suggestedResolution:
              'Keep this rule enabled only if the school uses zero '
              'periods.',
          affectedRecordId: null,
          affectedDate: null,
        ),
      );
    }

    return checks;
  }

  static bool _overlaps(
    DateTime startA,
    DateTime endA,
    DateTime startB,
    DateTime endB,
  ) {
    return !endA.isBefore(startB) && !endB.isBefore(startA);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int _severityWeight(AcademicCalendarConflictSeverity severity) =>
      switch (severity) {
        AcademicCalendarConflictSeverity.error => 3,
        AcademicCalendarConflictSeverity.warning => 2,
        AcademicCalendarConflictSeverity.info => 1,
      };

  static AcademicCalendarConflictModule _moduleForEvent(
    AcademicCalendarEventType type,
  ) => switch (type) {
    AcademicCalendarEventType.exam => AcademicCalendarConflictModule.exams,
    AcademicCalendarEventType.meeting => AcademicCalendarConflictModule.notices,
    _ => AcademicCalendarConflictModule.calendar,
  };

  static String _weekday(int weekday) => const {
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  }[weekday]!;
}
