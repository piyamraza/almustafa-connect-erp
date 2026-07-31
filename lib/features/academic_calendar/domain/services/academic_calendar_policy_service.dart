import '../entities/academic_calendar_event_entity.dart';
import '../entities/academic_year_config_entity.dart';

class AcademicCalendarPolicyDecision {
  const AcademicCalendarPolicyDecision({
    required this.allowed,
    required this.message,
    this.suggestedDate,
  });

  final bool allowed;
  final String message;
  final DateTime? suggestedDate;
}

abstract class AcademicCalendarPolicyService {
  Future<AcademicYearConfigEntity?> getConfig(String academicSession);

  Future<AcademicCalendarPolicyDecision> validateAttendanceDate({
    required String academicSession,
    required DateTime date,
  });

  Future<AcademicCalendarPolicyDecision> validateTimetableDate({
    required String academicSession,
    required DateTime date,
    required bool usesZeroPeriod,
  });

  Future<AcademicCalendarPolicyDecision> validateHomeworkDueDate({
    required String academicSession,
    required DateTime date,
  });

  Future<AcademicCalendarPolicyDecision> validateExamDate({
    required String academicSession,
    required DateTime date,
  });

  Future<DateTime> resolveFeeGenerationDate({
    required String academicSession,
    required int month,
    required int year,
  });

  Future<DateTime> resolveFeeDueDate({
    required String academicSession,
    required int month,
    required int year,
  });

  Future<DateTime> nextWorkingDay({
    required String academicSession,
    required DateTime from,
  });

  Future<List<AcademicCalendarEventEntity>> getVisibleEvents({
    required String academicSession,
    required AcademicCalendarAudience audience,
    required DateTime startDate,
    required DateTime endDate,
    List<String> classIds = const [],
  });
}
