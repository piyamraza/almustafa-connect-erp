import '../entities/student_development_profile_entity.dart';

abstract class StudentDevelopmentProfileRepository {
  Future<StudentDevelopmentProfileEntity?> getForStudent({
    required String examId,
    required String studentId,
  });

  Future<List<StudentDevelopmentProfileEntity>> getForExam(String examId);

  Future<StudentDevelopmentProfileEntity?> getLatestForStudentSession({
    required String studentId,
    required String academicSession,
  });

  Future<void> saveAll(List<StudentDevelopmentProfileEntity> profiles);
}
