import '../entities/teacher_entity.dart';

abstract class TeacherRepository {
  Future<List<TeacherEntity>> getTeachers();
  Future<void> saveTeacher(TeacherEntity teacher);
  Future<void> deleteTeacher(String id);
  String generateTeacherId();
}
