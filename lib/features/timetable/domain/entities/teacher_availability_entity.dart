import 'package:equatable/equatable.dart';

class TeacherUnavailableSlot extends Equatable {
  const TeacherUnavailableSlot({required this.weekday, required this.periodId});

  final int weekday;
  final String periodId;

  String get key => '$weekday|$periodId';

  @override
  List<Object> get props => [weekday, periodId];
}

class TeacherAvailabilityEntity extends Equatable {
  TeacherAvailabilityEntity({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.branchId,
    required this.academicSession,
    required List<int> weeklyOffDays,
    required List<TeacherUnavailableSlot> unavailableSlots,
    required this.maxPeriodsPerDay,
    required this.maxPeriodsPerWeek,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : weeklyOffDays = List<int>.unmodifiable(weeklyOffDays),
       unavailableSlots = List<TeacherUnavailableSlot>.unmodifiable(
         unavailableSlots,
       );

  final String id;
  final String teacherId;
  final String teacherName;
  final String branchId;
  final String academicSession;
  final List<int> weeklyOffDays;
  final List<TeacherUnavailableSlot> unavailableSlots;
  final int maxPeriodsPerDay;
  final int maxPeriodsPerWeek;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isAvailable({
    required int weekday,
    required String periodId,
    required int assignedOnDay,
    required int assignedInWeek,
  }) {
    if (!isActive) return true;
    if (weeklyOffDays.contains(weekday)) return false;
    if (unavailableSlots.any(
      (slot) => slot.weekday == weekday && slot.periodId == periodId,
    )) {
      return false;
    }
    if (maxPeriodsPerDay > 0 && assignedOnDay >= maxPeriodsPerDay) {
      return false;
    }
    if (maxPeriodsPerWeek > 0 && assignedInWeek >= maxPeriodsPerWeek) {
      return false;
    }
    return true;
  }

  @override
  List<Object> get props => [
    id,
    teacherId,
    teacherName,
    branchId,
    academicSession,
    weeklyOffDays,
    unavailableSlots,
    maxPeriodsPerDay,
    maxPeriodsPerWeek,
    isActive,
    createdAt,
    updatedAt,
  ];
}
