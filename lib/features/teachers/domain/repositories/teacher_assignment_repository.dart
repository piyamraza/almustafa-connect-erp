import '../entities/teacher_assignment_entity.dart';
abstract class TeacherAssignmentRepository { Future<List<TeacherAssignmentEntity>> getAssignments(); Future<List<TeacherAssignmentEntity>> getAssignmentsForTeacher(String teacherId); Future<void> saveAssignment(TeacherAssignmentEntity assignment); Future<void> deleteAssignment(String id); String generateId(); }
