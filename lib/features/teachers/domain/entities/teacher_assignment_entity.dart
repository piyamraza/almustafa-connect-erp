import 'package:equatable/equatable.dart';

class TeacherAssignmentEntity extends Equatable {
  const TeacherAssignmentEntity({required this.id, required this.teacherId, required this.teacherName, required this.classId, required this.sectionId, required this.subject, required this.academicSession, required this.isClassTeacher, required this.createdAt});
  final String id, teacherId, teacherName, classId, sectionId, subject, academicSession;
  final bool isClassTeacher;
  final DateTime createdAt;
  @override List<Object> get props => [id, teacherId, teacherName, classId, sectionId, subject, academicSession, isClassTeacher, createdAt];
}
