import '../../domain/entities/class_timetable_entry_entity.dart';

class ClassTimetableEntryModel extends ClassTimetableEntryEntity {
  const ClassTimetableEntryModel({
    required super.id,
    required super.branchId,
    required super.academicSession,
    required super.classId,
    required super.className,
    required super.sectionId,
    required super.sectionName,
    required super.weekday,
    required super.periodId,
    required super.periodLabel,
    required super.periodOrder,
    required super.subjectId,
    required super.subjectName,
    required super.teacherId,
    required super.teacherName,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ClassTimetableEntryModel.fromMap(Map<String, dynamic> map) {
    return ClassTimetableEntryModel(
      id: map['id'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      sectionName: map['sectionName'] as String? ?? '',
      weekday: (map['weekday'] as num?)?.toInt() ?? 0,
      periodId: map['periodId'] as String? ?? '',
      periodLabel: map['periodLabel'] as String? ?? '',
      periodOrder: (map['periodOrder'] as num?)?.toInt() ?? 0,
      subjectId: map['subjectId'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      createdAt: _dateTime(map['createdAt']),
      updatedAt: _dateTime(map['updatedAt']),
    );
  }

  factory ClassTimetableEntryModel.fromEntity(ClassTimetableEntryEntity value) {
    return ClassTimetableEntryModel(
      id: value.id,
      branchId: value.branchId,
      academicSession: value.academicSession,
      classId: value.classId,
      className: value.className,
      sectionId: value.sectionId,
      sectionName: value.sectionName,
      weekday: value.weekday,
      periodId: value.periodId,
      periodLabel: value.periodLabel,
      periodOrder: value.periodOrder,
      subjectId: value.subjectId,
      subjectName: value.subjectName,
      teacherId: value.teacherId,
      teacherName: value.teacherName,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'branchId': branchId,
    'academicSession': academicSession,
    'classId': classId,
    'className': className,
    'sectionId': sectionId,
    'sectionName': sectionName,
    'weekday': weekday,
    'periodId': periodId,
    'periodLabel': periodLabel,
    'periodOrder': periodOrder,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'teacherId': teacherId,
    'teacherName': teacherName,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static DateTime _dateTime(Object? value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
