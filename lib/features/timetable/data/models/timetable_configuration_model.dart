import '../../domain/entities/timetable_configuration_entity.dart';
import '../../domain/entities/timetable_period_entity.dart';
import 'timetable_period_model.dart';

class TimetableConfigurationModel extends TimetableConfigurationEntity {
  TimetableConfigurationModel({
    required super.id,
    required super.branchId,
    required super.academicSession,
    required super.workingDays,
    required super.schoolOpeningMinutes,
    required super.schoolClosingMinutes,
    required super.periods,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TimetableConfigurationModel.fromMap(Map<String, dynamic> map) {
    final rawWorkingDays = map['workingDays'] as List<dynamic>? ?? const [];
    final rawPeriods = map['periods'] as List<dynamic>? ?? const [];

    return TimetableConfigurationModel(
      id: map['id'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      workingDays: rawWorkingDays
          .whereType<num>()
          .map((day) => day.toInt())
          .toList(growable: false),
      schoolOpeningMinutes: (map['schoolOpeningMinutes'] as num?)?.toInt() ?? 0,
      schoolClosingMinutes: (map['schoolClosingMinutes'] as num?)?.toInt() ?? 0,
      periods: rawPeriods
          .whereType<Map>()
          .map(
            (period) =>
                TimetablePeriodModel.fromMap(Map<String, dynamic>.from(period)),
          )
          .toList(growable: false),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _dateTime(map['createdAt']),
      updatedAt: _dateTime(map['updatedAt']),
    );
  }

  factory TimetableConfigurationModel.fromEntity(
    TimetableConfigurationEntity value,
  ) {
    return TimetableConfigurationModel(
      id: value.id,
      branchId: value.branchId,
      academicSession: value.academicSession,
      workingDays: value.workingDays,
      schoolOpeningMinutes: value.schoolOpeningMinutes,
      schoolClosingMinutes: value.schoolClosingMinutes,
      periods: value.periods
          .map<TimetablePeriodEntity>(TimetablePeriodModel.fromEntity)
          .toList(growable: false),
      isActive: value.isActive,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'branchId': branchId,
    'academicSession': academicSession,
    'workingDays': workingDays,
    'schoolOpeningMinutes': schoolOpeningMinutes,
    'schoolClosingMinutes': schoolClosingMinutes,
    'periods': periods
        .map((period) => TimetablePeriodModel.fromEntity(period).toMap())
        .toList(growable: false),
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static DateTime _dateTime(Object? value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
