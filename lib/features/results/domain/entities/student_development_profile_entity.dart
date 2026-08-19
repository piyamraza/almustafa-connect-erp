import 'package:equatable/equatable.dart';

class StudentDevelopmentProfileEntity extends Equatable {
  const StudentDevelopmentProfileEntity({
    required this.id,
    required this.examId,
    required this.academicSession,
    required this.studentId,
    required this.classId,
    required this.sectionId,
    this.discipline = 0,
    this.communication = 0,
    this.classParticipation = 0,
    this.homework = 0,
    this.personalHygiene = 0,
    this.updatedBy = '',
    this.updatedAt,
  });

  final String id;
  final String examId;
  final String academicSession;
  final String studentId;
  final String classId;
  final String sectionId;
  final int discipline;
  final int communication;
  final int classParticipation;
  final int homework;
  final int personalHygiene;
  final String updatedBy;
  final DateTime? updatedAt;

  bool get isComplete =>
      discipline > 0 &&
      communication > 0 &&
      classParticipation > 0 &&
      homework > 0 &&
      personalHygiene > 0;

  static String documentIdFor(String examId, String studentId) =>
      '${examId.trim()}_${studentId.trim()}';

  StudentDevelopmentProfileEntity copyWith({
    int? discipline,
    int? communication,
    int? classParticipation,
    int? homework,
    int? personalHygiene,
    String? updatedBy,
    DateTime? updatedAt,
  }) => StudentDevelopmentProfileEntity(
    id: id,
    examId: examId,
    academicSession: academicSession,
    studentId: studentId,
    classId: classId,
    sectionId: sectionId,
    discipline: discipline ?? this.discipline,
    communication: communication ?? this.communication,
    classParticipation: classParticipation ?? this.classParticipation,
    homework: homework ?? this.homework,
    personalHygiene: personalHygiene ?? this.personalHygiene,
    updatedBy: updatedBy ?? this.updatedBy,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    examId,
    academicSession,
    studentId,
    classId,
    sectionId,
    discipline,
    communication,
    classParticipation,
    homework,
    personalHygiene,
    updatedBy,
    updatedAt,
  ];
}
