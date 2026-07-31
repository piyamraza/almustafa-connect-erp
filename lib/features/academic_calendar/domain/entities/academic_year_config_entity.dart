import 'package:equatable/equatable.dart';

class AcademicDateRangeEntity extends Equatable {
  const AcademicDateRangeEntity({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object> get props => [id, title, startDate, endDate];
}

class AcademicYearConfigEntity extends Equatable {
  AcademicYearConfigEntity({
    required this.id,
    required this.academicSession,
    required this.startDate,
    required this.endDate,
    required Set<int> workingWeekdays,
    required List<AcademicDateRangeEntity> vacations,
    required List<AcademicDateRangeEntity> examWindows,
    required this.feeGenerationDay,
    required this.feeDueDay,
    required this.feeReminderBeforeDays,
    required this.feeReminderAfterDays,
    required Set<int> homeworkAllowedWeekdays,
    required this.homeworkAllowedOnHolidays,
    required this.homeworkAllowedInVacations,
    required this.zeroPeriodAllowed,
    required this.saturdayTimetableAllowed,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : workingWeekdays = Set<int>.unmodifiable(workingWeekdays),
       vacations = List<AcademicDateRangeEntity>.unmodifiable(vacations),
       examWindows = List<AcademicDateRangeEntity>.unmodifiable(examWindows),
       homeworkAllowedWeekdays = Set<int>.unmodifiable(homeworkAllowedWeekdays);

  final String id;
  final String academicSession;
  final DateTime startDate;
  final DateTime endDate;
  final Set<int> workingWeekdays;
  final List<AcademicDateRangeEntity> vacations;
  final List<AcademicDateRangeEntity> examWindows;
  final int feeGenerationDay;
  final int feeDueDay;
  final int feeReminderBeforeDays;
  final int feeReminderAfterDays;
  final Set<int> homeworkAllowedWeekdays;
  final bool homeworkAllowedOnHolidays;
  final bool homeworkAllowedInVacations;
  final bool zeroPeriodAllowed;
  final bool saturdayTimetableAllowed;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get totalCalendarDays => endDate.difference(startDate).inDays + 1;

  int get totalWorkingDays {
    var count = 0;
    var cursor = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (!cursor.isAfter(end)) {
      if (workingWeekdays.contains(cursor.weekday) && !isVacationDate(cursor)) {
        count++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }

  int get vacationDays {
    var count = 0;
    for (final vacation in vacations) {
      count += vacation.endDate.difference(vacation.startDate).inDays + 1;
    }
    return count;
  }

  int get examDays {
    final dates = <DateTime>{};
    for (final window in examWindows) {
      var cursor = DateTime(
        window.startDate.year,
        window.startDate.month,
        window.startDate.day,
      );
      final end = DateTime(
        window.endDate.year,
        window.endDate.month,
        window.endDate.day,
      );
      while (!cursor.isAfter(end)) {
        dates.add(cursor);
        cursor = cursor.add(const Duration(days: 1));
      }
    }
    return dates.length;
  }

  int get availableTeachingDays {
    final value = totalWorkingDays - examDays;
    return value < 0 ? 0 : value;
  }

  bool isVacationDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return vacations.any((range) {
      final start = DateTime(
        range.startDate.year,
        range.startDate.month,
        range.startDate.day,
      );
      final end = DateTime(
        range.endDate.year,
        range.endDate.month,
        range.endDate.day,
      );
      return !day.isBefore(start) && !day.isAfter(end);
    });
  }

  @override
  List<Object> get props => [
    id,
    academicSession,
    startDate,
    endDate,
    workingWeekdays,
    vacations,
    examWindows,
    feeGenerationDay,
    feeDueDay,
    feeReminderBeforeDays,
    feeReminderAfterDays,
    homeworkAllowedWeekdays,
    homeworkAllowedOnHolidays,
    homeworkAllowedInVacations,
    zeroPeriodAllowed,
    saturdayTimetableAllowed,
    isActive,
    createdAt,
    updatedAt,
  ];
}
