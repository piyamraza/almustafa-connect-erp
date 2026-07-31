import 'package:equatable/equatable.dart';

class TeacherAssignmentEntity extends Equatable {
  const TeacherAssignmentEntity({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.classId,
    required this.sectionId,
    required this.subject,
    required this.academicSession,
    required this.isClassTeacher,
    required this.createdAt,
  });

  final String id;
  final String teacherId;
  final String teacherName;
  final String classId;
  final String sectionId;
  final String subject;
  final String academicSession;
  final bool isClassTeacher;
  final DateTime createdAt;

  String get assignmentKey => [
        academicSession,
        classId,
        sectionId,
        subject,
      ].map(_keyPart).join('|');

  String get classTeacherKey => [
        academicSession,
        classId,
        sectionId,
      ].map(_keyPart).join('|');

  static String _keyPart(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  @override
  List<Object> get props => [
        id,
        teacherId,
        teacherName,
        classId,
        sectionId,
        subject,
        academicSession,
        isClassTeacher,
        createdAt,
      ];
}
