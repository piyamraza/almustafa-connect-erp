import 'dart:typed_data';

import '../entities/student_entity.dart';

abstract class StudentRepository {
  Future<List<StudentEntity>> getStudents();

  Future<StudentEntity?> getStudentById(String id);

  Future<void> addStudent(StudentEntity student);

  Future<void> updateStudent(StudentEntity student);

  Future<void> deleteStudent(String id);

  Future<List<StudentEntity>> searchStudents(String keyword);

  String generateStudentId();

  Future<String> uploadStudentPhoto(
    String studentId,
    Uint8List imageBytes,
  );
}