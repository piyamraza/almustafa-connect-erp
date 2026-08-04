import 'package:equatable/equatable.dart';

enum TeacherLeaveStatus {
  pending,
  approved,
  rejected,
}

class TeacherLeaveRequestEntity extends Equatable {
  const TeacherLeaveRequestEntity({
    required this.id,
    required this.teacherEmail,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String teacherEmail;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final TeacherLeaveStatus status;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        teacherEmail,
        fromDate,
        toDate,
        reason,
        status,
        createdAt,
      ];
}

class SubstituteDutyEntity extends Equatable {
  const SubstituteDutyEntity({
    required this.id,
    required this.originalTeacherEmail,
    required this.substituteTeacherEmail,
    required this.dutyDate,
    required this.periodLabel,
    required this.className,
    required this.sectionName,
    required this.subjectName,
    required this.room,
    required this.notes,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String originalTeacherEmail;
  final String substituteTeacherEmail;
  final DateTime dutyDate;
  final String periodLabel;
  final String className;
  final String sectionName;
  final String subjectName;
  final String room;
  final String notes;
  final bool isActive;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        originalTeacherEmail,
        substituteTeacherEmail,
        dutyDate,
        periodLabel,
        className,
        sectionName,
        subjectName,
        room,
        notes,
        isActive,
        createdAt,
      ];
}