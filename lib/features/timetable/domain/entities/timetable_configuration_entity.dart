import 'package:equatable/equatable.dart';

import 'timetable_period_entity.dart';

class TimetableConfigurationEntity extends Equatable {
  TimetableConfigurationEntity({
    required this.id,
    required this.branchId,
    required this.academicSession,
    required List<int> workingDays,
    required this.schoolOpeningMinutes,
    required this.schoolClosingMinutes,
    required List<TimetablePeriodEntity> periods,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : workingDays = List<int>.unmodifiable(workingDays),
       periods = List<TimetablePeriodEntity>.unmodifiable(periods);

  final String id;
  final String branchId;
  final String academicSession;

  /// Uses DateTime weekday values: Monday = 1 and Sunday = 7.
  final List<int> workingDays;

  /// Minutes elapsed since midnight.
  final int schoolOpeningMinutes;

  /// Minutes elapsed since midnight.
  final int schoolClosingMinutes;
  final List<TimetablePeriodEntity> periods;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get teachingPeriodCount =>
      periods.where((period) => period.isTeaching).length;

  List<TimetablePeriodEntity> get orderedPeriods {
    final values = List<TimetablePeriodEntity>.of(periods)
      ..sort((first, second) => first.order.compareTo(second.order));
    return List<TimetablePeriodEntity>.unmodifiable(values);
  }

  List<String> get validationErrors {
    final errors = <String>[];

    if (id.trim().isEmpty) {
      errors.add('Timetable configuration ID is required.');
    }
    if (branchId.trim().isEmpty) {
      errors.add('Branch is required.');
    }
    if (academicSession.trim().isEmpty) {
      errors.add('Academic session is required.');
    }
    if (workingDays.isEmpty) {
      errors.add('At least one working day is required.');
    }
    if (workingDays.any(
      (day) => day < DateTime.monday || day > DateTime.sunday,
    )) {
      errors.add('Working days contain an invalid weekday.');
    }
    if (workingDays.toSet().length != workingDays.length) {
      errors.add('Working days cannot contain duplicates.');
    }
    if (schoolOpeningMinutes < 0 || schoolOpeningMinutes >= 1440) {
      errors.add('School opening time is invalid.');
    }
    if (schoolClosingMinutes <= 0 || schoolClosingMinutes > 1440) {
      errors.add('School closing time is invalid.');
    }
    if (schoolClosingMinutes <= schoolOpeningMinutes) {
      errors.add('School closing time must be after opening time.');
    }
    if (periods.isEmpty) {
      errors.add('At least one timetable period is required.');
      return errors;
    }
    if (teachingPeriodCount == 0) {
      errors.add('At least one teaching period is required.');
    }

    final periodIds = <String>{};
    final periodOrders = <int>{};
    final ordered = orderedPeriods;

    for (final period in ordered) {
      errors.addAll(
        period.validationErrors.map((error) => '${period.label}: $error'),
      );

      if (!periodIds.add(period.id.trim().toLowerCase())) {
        errors.add('Period IDs cannot be duplicated.');
      }
      if (!periodOrders.add(period.order)) {
        errors.add('Period order cannot be duplicated.');
      }
      if (period.startMinutes < schoolOpeningMinutes ||
          period.endMinutes > schoolClosingMinutes) {
        errors.add('${period.label} must be within school opening hours.');
      }
    }

    for (var index = 1; index < ordered.length; index++) {
      final previous = ordered[index - 1];
      final current = ordered[index];
      if (current.startMinutes < previous.endMinutes) {
        errors.add('${current.label} overlaps ${previous.label}.');
      }
    }

    return errors.toSet().toList(growable: false);
  }

  TimetableConfigurationEntity copyWith({
    String? id,
    String? branchId,
    String? academicSession,
    List<int>? workingDays,
    int? schoolOpeningMinutes,
    int? schoolClosingMinutes,
    List<TimetablePeriodEntity>? periods,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimetableConfigurationEntity(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      academicSession: academicSession ?? this.academicSession,
      workingDays: workingDays ?? this.workingDays,
      schoolOpeningMinutes: schoolOpeningMinutes ?? this.schoolOpeningMinutes,
      schoolClosingMinutes: schoolClosingMinutes ?? this.schoolClosingMinutes,
      periods: periods ?? this.periods,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    branchId,
    academicSession,
    workingDays,
    schoolOpeningMinutes,
    schoolClosingMinutes,
    periods,
    isActive,
    createdAt,
    updatedAt,
  ];
}
