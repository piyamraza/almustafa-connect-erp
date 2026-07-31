import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/academic_year_config_entity.dart';

class AcademicYearConfigModel extends AcademicYearConfigEntity {
  AcademicYearConfigModel({
    required super.id,
    required super.academicSession,
    required super.startDate,
    required super.endDate,
    required super.workingWeekdays,
    required super.vacations,
    required super.examWindows,
    required super.feeGenerationDay,
    required super.feeDueDay,
    required super.feeReminderBeforeDays,
    required super.feeReminderAfterDays,
    required super.homeworkAllowedWeekdays,
    required super.homeworkAllowedOnHolidays,
    required super.homeworkAllowedInVacations,
    required super.zeroPeriodAllowed,
    required super.saturdayTimetableAllowed,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AcademicYearConfigModel.fromEntity(AcademicYearConfigEntity entity) {
    return AcademicYearConfigModel(
      id: entity.id,
      academicSession: entity.academicSession,
      startDate: entity.startDate,
      endDate: entity.endDate,
      workingWeekdays: entity.workingWeekdays,
      vacations: entity.vacations,
      examWindows: entity.examWindows,
      feeGenerationDay: entity.feeGenerationDay,
      feeDueDay: entity.feeDueDay,
      feeReminderBeforeDays: entity.feeReminderBeforeDays,
      feeReminderAfterDays: entity.feeReminderAfterDays,
      homeworkAllowedWeekdays: entity.homeworkAllowedWeekdays,
      homeworkAllowedOnHolidays: entity.homeworkAllowedOnHolidays,
      homeworkAllowedInVacations: entity.homeworkAllowedInVacations,
      zeroPeriodAllowed: entity.zeroPeriodAllowed,
      saturdayTimetableAllowed: entity.saturdayTimetableAllowed,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory AcademicYearConfigModel.fromMap(Map<String, dynamic> map) {
    return AcademicYearConfigModel(
      id: map['id'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      startDate: _date(map['startDate']),
      endDate: _date(map['endDate']),
      workingWeekdays: (map['workingWeekdays'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((item) => item.toInt())
          .toSet(),
      vacations: _ranges(map['vacations']),
      examWindows: _ranges(map['examWindows']),
      feeGenerationDay: (map['feeGenerationDay'] as num?)?.toInt() ?? 1,
      feeDueDay: (map['feeDueDay'] as num?)?.toInt() ?? 10,
      feeReminderBeforeDays:
          (map['feeReminderBeforeDays'] as num?)?.toInt() ?? 3,
      feeReminderAfterDays: (map['feeReminderAfterDays'] as num?)?.toInt() ?? 2,
      homeworkAllowedWeekdays:
          (map['homeworkAllowedWeekdays'] as List<dynamic>? ?? const [])
              .whereType<num>()
              .map((item) => item.toInt())
              .toSet(),
      homeworkAllowedOnHolidays:
          map['homeworkAllowedOnHolidays'] as bool? ?? false,
      homeworkAllowedInVacations:
          map['homeworkAllowedInVacations'] as bool? ?? false,
      zeroPeriodAllowed: map['zeroPeriodAllowed'] as bool? ?? false,
      saturdayTimetableAllowed:
          map['saturdayTimetableAllowed'] as bool? ?? true,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'academicSession': academicSession,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'workingWeekdays': workingWeekdays.toList()..sort(),
    'vacations': vacations
        .map(
          (item) => {
            'id': item.id,
            'title': item.title,
            'startDate': Timestamp.fromDate(item.startDate),
            'endDate': Timestamp.fromDate(item.endDate),
          },
        )
        .toList(growable: false),
    'examWindows': examWindows
        .map(
          (item) => {
            'id': item.id,
            'title': item.title,
            'startDate': Timestamp.fromDate(item.startDate),
            'endDate': Timestamp.fromDate(item.endDate),
          },
        )
        .toList(growable: false),
    'feeGenerationDay': feeGenerationDay,
    'feeDueDay': feeDueDay,
    'feeReminderBeforeDays': feeReminderBeforeDays,
    'feeReminderAfterDays': feeReminderAfterDays,
    'homeworkAllowedWeekdays': homeworkAllowedWeekdays.toList()..sort(),
    'homeworkAllowedOnHolidays': homeworkAllowedOnHolidays,
    'homeworkAllowedInVacations': homeworkAllowedInVacations,
    'zeroPeriodAllowed': zeroPeriodAllowed,
    'saturdayTimetableAllowed': saturdayTimetableAllowed,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static List<AcademicDateRangeEntity> _ranges(dynamic value) {
    final raw = value as List<dynamic>? ?? const <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => AcademicDateRangeEntity(
            id: item['id'] as String? ?? '',
            title: item['title'] as String? ?? '',
            startDate: _date(item['startDate']),
            endDate: _date(item['endDate']),
          ),
        )
        .toList(growable: false);
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
