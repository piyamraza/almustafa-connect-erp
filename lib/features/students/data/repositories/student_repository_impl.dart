import 'dart:typed_data';

import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/student_repository.dart';
import '../datasources/student_remote_datasource.dart';
import '../models/student_model.dart';

class StudentRepositoryImpl implements StudentRepository {
  StudentRepositoryImpl({
    required StudentRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final StudentRemoteDataSource _remoteDataSource;

  @override
  Future<List<StudentEntity>> getStudents() {
    return _remoteDataSource.getStudents();
  }

  @override
  Future<List<StudentEntity>> getStudentsByClassAndSection({
    required String classId,
    required String sectionId,
  }) {
    return _remoteDataSource.getStudentsByClassAndSection(
      classId: classId,
      sectionId: sectionId,
    );
  }

  @override
  Future<StudentEntity?> getStudentById(String id) {
    return _remoteDataSource.getStudentById(id);
  }

  @override
  Future<void> addStudent(StudentEntity student) {
    return _remoteDataSource.addStudent(
      StudentModel.fromEntity(student),
    );
  }

  @override
  Future<void> updateStudent(StudentEntity student) {
    return _remoteDataSource.updateStudent(
      StudentModel.fromEntity(student),
    );
  }

  @override
  Future<void> deleteStudent(String id) {
    return _remoteDataSource.deleteStudent(id);
  }

  @override
  Future<List<StudentEntity>> searchStudents(String keyword) {
    return _remoteDataSource.searchStudents(keyword);
  }

  @override
  String generateStudentId() {
    return _remoteDataSource.generateStudentId();
  }

  @override
  Future<String> uploadStudentPhoto(
    String studentId,
    Uint8List imageBytes,
  ) {
    return _remoteDataSource.uploadStudentPhoto(
      studentId,
      imageBytes,
    );
  }
}
