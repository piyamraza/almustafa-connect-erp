import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/teacher_availability_entity.dart';

class TeacherAvailabilityModel extends TeacherAvailabilityEntity {
  TeacherAvailabilityModel({
    required super.id,
    required super.teacherId,
    required super.teacherName,
    required super.branchId,
    required super.academicSession,
    required super.weeklyOffDays,
    required super.unavailableSlots,
    required super.maxPeriodsPerDay,
    required super.maxPeriodsPerWeek,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TeacherAvailabilityModel.fromEntity(
    TeacherAvailabilityEntity entity,
  ) {
    return TeacherAvailabilityModel(
      id: entity.id,
      teacherId: entity.teacherId,
      teacherName: entity.teacherName,
      branchId: entity.branchId,
      academicSession: entity.academicSession,
      weeklyOffDays: entity.weeklyOffDays,
      unavailableSlots: entity.unavailableSlots,
      maxPeriodsPerDay: entity.maxPeriodsPerDay,
      maxPeriodsPerWeek: entity.maxPeriodsPerWeek,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory TeacherAvailabilityModel.fromMap(Map<String, dynamic> map) {
    final slots = (map['unavailableSlots'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (value) => TeacherUnavailableSlot(
            weekday: (value['weekday'] as num?)?.toInt() ?? 0,
            periodId: value['periodId'] as String? ?? '',
          ),
        )
        .toList(growable: false);

    return TeacherAvailabilityModel(
      id: map['id'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      weeklyOffDays: (map['weeklyOffDays'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((value) => value.toInt())
          .toList(growable: false),
      unavailableSlots: slots,
      maxPeriodsPerDay: (map['maxPeriodsPerDay'] as num?)?.toInt() ?? 0,
      maxPeriodsPerWeek: (map['maxPeriodsPerWeek'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'teacherId': teacherId,
    'teacherName': teacherName,
    'branchId': branchId,
    'academicSession': academicSession,
    'weeklyOffDays': weeklyOffDays,
    'unavailableSlots': unavailableSlots
        .map((slot) => {'weekday': slot.weekday, 'periodId': slot.periodId})
        .toList(growable: false),
    'maxPeriodsPerDay': maxPeriodsPerDay,
    'maxPeriodsPerWeek': maxPeriodsPerWeek,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
