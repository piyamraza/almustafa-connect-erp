import '../entities/teacher_assignment_entity.dart';
abstract class TeacherAssignmentRepository { Future<List<TeacherAssignmentEntity>> getAssignments(); Future<void> saveAssignment(TeacherAssignmentEntity assignment); Future<void> deleteAssignment(String id); String generateId(); }
