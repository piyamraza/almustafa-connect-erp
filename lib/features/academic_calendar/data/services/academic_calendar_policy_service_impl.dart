import '../../domain/entities/academic_calendar_event_entity.dart';
import '../../domain/entities/academic_year_config_entity.dart';
import '../../domain/repositories/academic_calendar_repository.dart';
import '../../domain/repositories/academic_year_config_repository.dart';
import '../../domain/services/academic_calendar_policy_service.dart';

class AcademicCalendarPolicyServiceImpl
    implements AcademicCalendarPolicyService {
  const AcademicCalendarPolicyServiceImpl(
    this._configRepository,
    this._calendarRepository,
  );

  final AcademicYearConfigRepository _configRepository;
  final AcademicCalendarRepository _calendarRepository;

  @override
  Future<AcademicYearConfigEntity?> getConfig(String academicSession) {
    return _configRepository.getBySession(academicSession);
  }

  @override
  Future<AcademicCalendarPolicyDecision> validateAttendanceDate({
    required String academicSession,
    required DateTime date,
  }) async {
    final config = await _requiredConfig(academicSession);

    if (!_insideSession(config, date)) {
      return const AcademicCalendarPolicyDecision(
        allowed: false,
        message: 'Attendance date is outside the academic session.',
      );
    }

    if (!config.workingWeekdays.contains(date.weekday)) {
      return AcademicCalendarPolicyDecision(
        allowed: false,
        message: 'Attendance cannot be marked on a non-working day.',
        suggestedDate: await nextWorkingDay(
          academicSession: academicSession,
          from: date,
        ),
      );
    }

    if (config.isVacationDate(date) ||
        await _isHoliday(academicSession, date)) {
      return AcademicCalendarPolicyDecision(
        allowed: false,
        message: 'Attendance cannot be marked on a holiday or vacation.',
        suggestedDate: await nextWorkingDay(
          academicSession: academicSession,
          from: date,
        ),
      );
    }

    return const AcademicCalendarPolicyDecision(
      allowed: true,
      message: 'Attendance date is valid.',
    );
  }

  @override
  Future<AcademicCalendarPolicyDecision> validateTimetableDate({
    required String academicSession,
    required DateTime date,
    required bool usesZeroPeriod,
  }) async {
    final config = await _requiredConfig(academicSession);
    final attendance = await validateAttendanceDate(
      academicSession: academicSession,
      date: date,
    );

    if (!attendance.allowed) {
      return AcademicCalendarPolicyDecision(
        allowed: false,
        message: attendance.message.replaceFirst('Attendance', 'Timetable'),
        suggestedDate: attendance.suggestedDate,
      );
    }

    if (date.weekday == DateTime.saturday && !config.saturdayTimetableAllowed) {
      return const AcademicCalendarPolicyDecision(
        allowed: false,
        message: 'Saturday timetable is disabled in Academic Year Wizard.',
      );
    }

    if (usesZeroPeriod && !config.zeroPeriodAllowed) {
      return const AcademicCalendarPolicyDecision(
        allowed: false,
        message: 'Zero period is disabled in Academic Year Wizard.',
      );
    }

    return const AcademicCalendarPolicyDecision(
      allowed: true,
      message: 'Timetable date is valid.',
    );
  }

  @override
  Future<AcademicCalendarPolicyDecision> validateHomeworkDueDate({
    required String academicSession,
    required DateTime date,
  }) async {
    final config = await _requiredConfig(academicSession);

    if (!_insideSession(config, date)) {
      return const AcademicCalendarPolicyDecision(
        allowed: false,
        message: 'Homework due date is outside the academic session.',
      );
    }

    if (config.isVacationDate(date) && !config.homeworkAllowedInVacations) {
      return AcademicCalendarPolicyDecision(
        allowed: false,
        message: 'Homework is not allowed during vacations.',
        suggestedDate: await nextWorkingDay(
          academicSession: academicSession,
          from: date,
        ),
      );
    }

    if (await _isHoliday(academicSession, date) &&
        !config.homeworkAllowedOnHolidays) {
      return AcademicCalendarPolicyDecision(
        allowed: false,
        message: 'Homework is not allowed on holidays.',
        suggestedDate: await nextWorkingDay(
          academicSession: academicSession,
          from: date,
        ),
      );
    }

    if (!config.homeworkAllowedWeekdays.contains(date.weekday)) {
      return AcademicCalendarPolicyDecision(
        allowed: false,
        message: 'Homework is not allowed on this weekday.',
        suggestedDate: await nextWorkingDay(
          academicSession: academicSession,
          from: date,
        ),
      );
    }

    return const AcademicCalendarPolicyDecision(
      allowed: true,
      message: 'Homework due date is valid.',
    );
  }

  @override
  Future<AcademicCalendarPolicyDecision> validateExamDate({
    required String academicSession,
    required DateTime date,
  }) async {
    final config = await _requiredConfig(academicSession);

    if (config.isVacationDate(date) ||
        await _isHoliday(academicSession, date)) {
      return const AcademicCalendarPolicyDecision(
        allowed: false,
        message: 'Exam cannot be scheduled on a holiday or vacation.',
      );
    }

    final insideWindow = config.examWindows.any(
      (window) => _insideRange(date, window.startDate, window.endDate),
    );

    if (config.examWindows.isNotEmpty && !insideWindow) {
      return const AcademicCalendarPolicyDecision(
        allowed: false,
        message: 'Exam date is outside configured exam windows.',
      );
    }

    return const AcademicCalendarPolicyDecision(
      allowed: true,
      message: 'Exam date is valid.',
    );
  }

  @override
  Future<DateTime> resolveFeeGenerationDate({
    required String academicSession,
    required int month,
    required int year,
  }) async {
    final config = await _requiredConfig(academicSession);
    return _resolveWorkingDate(
      academicSession,
      DateTime(year, month, config.feeGenerationDay),
    );
  }

  @override
  Future<DateTime> resolveFeeDueDate({
    required String academicSession,
    required int month,
    required int year,
  }) async {
    final config = await _requiredConfig(academicSession);
    return _resolveWorkingDate(
      academicSession,
      DateTime(year, month, config.feeDueDay),
    );
  }

  @override
  Future<DateTime> nextWorkingDay({
    required String academicSession,
    required DateTime from,
  }) async {
    var candidate = DateTime(
      from.year,
      from.month,
      from.day,
    ).add(const Duration(days: 1));

    for (var attempt = 0; attempt < 370; attempt++) {
      final config = await _requiredConfig(academicSession);
      final working =
          config.workingWeekdays.contains(candidate.weekday) &&
          !config.isVacationDate(candidate) &&
          !await _isHoliday(academicSession, candidate);

      if (working) return candidate;
      candidate = candidate.add(const Duration(days: 1));
    }

    throw StateError('No working day could be resolved.');
  }

  @override
  Future<List<AcademicCalendarEventEntity>> getVisibleEvents({
    required String academicSession,
    required AcademicCalendarAudience audience,
    required DateTime startDate,
    required DateTime endDate,
    List<String> classIds = const [],
  }) async {
    final events = await _calendarRepository.getEvents(
      academicSession: academicSession,
      startDate: startDate,
      endDate: endDate,
      isActive: true,
    );

    return events
        .where((event) {
          if (event.audience == AcademicCalendarAudience.wholeSchool) {
            return true;
          }
          if (event.audience == audience) return true;
          if (event.audience == AcademicCalendarAudience.selectedClasses) {
            return event.classIds.any(classIds.contains);
          }
          return false;
        })
        .toList(growable: false);
  }

  Future<AcademicYearConfigEntity> _requiredConfig(String session) async {
    final config = await _configRepository.getBySession(session);
    if (config == null) {
      throw StateError(
        'Academic Year Wizard configuration is missing for $session.',
      );
    }
    return config;
  }

  Future<bool> _isHoliday(String session, DateTime date) async {
    final events = await _calendarRepository.getEvents(
      academicSession: session,
      startDate: date,
      endDate: date,
      isActive: true,
    );

    return events.any(
      (event) =>
          event.type == AcademicCalendarEventType.holiday ||
          event.type == AcademicCalendarEventType.vacation,
    );
  }

  Future<DateTime> _resolveWorkingDate(String session, DateTime date) async {
    final config = await _requiredConfig(session);
    final isWorking =
        config.workingWeekdays.contains(date.weekday) &&
        !config.isVacationDate(date) &&
        !await _isHoliday(session, date);

    if (isWorking) return date;

    return nextWorkingDay(
      academicSession: session,
      from: date.subtract(const Duration(days: 1)),
    );
  }

  static bool _insideSession(AcademicYearConfigEntity config, DateTime date) =>
      _insideRange(date, config.startDate, config.endDate);

  static bool _insideRange(DateTime date, DateTime start, DateTime end) {
    final day = DateTime(date.year, date.month, date.day);
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day);
    return !day.isBefore(from) && !day.isAfter(to);
  }
}
