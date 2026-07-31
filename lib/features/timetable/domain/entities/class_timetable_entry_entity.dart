import 'package:equatable/equatable.dart';

class ClassTimetableEntryEntity extends Equatable {
  const ClassTimetableEntryEntity({
    required this.id,
    required this.branchId,
    required this.academicSession,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.weekday,
    required this.periodId,
    required this.periodLabel,
    required this.periodOrder,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String branchId;
  final String academicSession;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final int weekday;
  final String periodId;
  final String periodLabel;
  final int periodOrder;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get slotKey => [
    branchId,
    academicSession,
    classId,
    sectionId,
    weekday.toString(),
    periodId,
  ].map(_keyPart).join('|');

  String get teacherSlotKey => [
    branchId,
    academicSession,
    teacherId,
    weekday.toString(),
    periodId,
  ].map(_keyPart).join('|');

  List<String> get validationErrors {
    final errors = <String>[];

    if (id.trim().isEmpty) {
      errors.add('Timetable entry ID is required.');
    }
    if (branchId.trim().isEmpty) {
      errors.add('Branch is required.');
    }
    if (academicSession.trim().isEmpty) {
      errors.add('Academic session is required.');
    }
    if (classId.trim().isEmpty) {
      errors.add('Class is required.');
    }
    if (className.trim().isEmpty) {
      errors.add('Class name is required.');
    }
    if (sectionId.trim().isEmpty) {
      errors.add('Section is required.');
    }
    if (sectionName.trim().isEmpty) {
      errors.add('Section name is required.');
    }
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      errors.add('Weekday is invalid.');
    }
    if (periodId.trim().isEmpty) {
      errors.add('Period is required.');
    }
    if (periodLabel.trim().isEmpty) {
      errors.add('Period label is required.');
    }
    if (periodOrder < 1) {
      errors.add('Period order is invalid.');
    }
    if (subjectId.trim().isEmpty) {
      errors.add('Subject is required.');
    }
    if (subjectName.trim().isEmpty) {
      errors.add('Subject name is required.');
    }
    if (teacherId.trim().isEmpty) {
      errors.add('Teacher is required.');
    }
    if (teacherName.trim().isEmpty) {
      errors.add('Teacher name is required.');
    }

    return errors;
  }

  ClassTimetableEntryEntity copyWith({
    String? id,
    String? branchId,
    String? academicSession,
    String? classId,
    String? className,
    String? sectionId,
    String? sectionName,
    int? weekday,
    String? periodId,
    String? periodLabel,
    int? periodOrder,
    String? subjectId,
    String? subjectName,
    String? teacherId,
    String? teacherName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassTimetableEntryEntity(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      academicSession: academicSession ?? this.academicSession,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      weekday: weekday ?? this.weekday,
      periodId: periodId ?? this.periodId,
      periodLabel: periodLabel ?? this.periodLabel,
      periodOrder: periodOrder ?? this.periodOrder,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _keyPart(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  @override
  List<Object> get props => [
    id,
    branchId,
    academicSession,
    classId,
    className,
    sectionId,
    sectionName,
    weekday,
    periodId,
    periodLabel,
    periodOrder,
    subjectId,
    subjectName,
    teacherId,
    teacherName,
    createdAt,
    updatedAt,
  ];
}
