import 'dart:typed_data';

import '../../../../core/audit/domain/services/audit_service.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/student_repository.dart';
import '../datasources/student_remote_datasource.dart';
import '../models/student_model.dart';

class StudentRepositoryImpl implements StudentRepository {
  StudentRepositoryImpl({
    required this._remoteDataSource,
    required this._auditService,
  });

  final StudentRemoteDataSource _remoteDataSource;
  final AuditService _auditService;

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
  Future<void> addStudent(StudentEntity student) async {
    final model = StudentModel.fromEntity(student);

    await _remoteDataSource.addStudent(model);

    await _auditService.logCreate(
      module: 'Students',
      recordId: student.id,
      description: 'Student record created',
      newValues: _auditValues(model),
    );
  }

  @override
  Future<void> updateStudent(StudentEntity student) async {
    final previous = await _remoteDataSource.getStudentById(student.id);
    final model = StudentModel.fromEntity(student);

    await _remoteDataSource.updateStudent(model);

    await _auditService.logUpdate(
      module: 'Students',
      recordId: student.id,
      description: 'Student record updated',
      oldValues: previous == null
          ? const {}
          : _auditValues(StudentModel.fromEntity(previous)),
      newValues: _auditValues(model),
    );
  }

  @override
  Future<void> deleteStudent(String id) async {
    final previous = await _remoteDataSource.getStudentById(id);

    await _remoteDataSource.deleteStudent(id);

    await _auditService.logDelete(
      module: 'Students',
      recordId: id,
      description: 'Student record deleted',
      oldValues: previous == null
          ? const {}
          : _auditValues(StudentModel.fromEntity(previous)),
    );
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
  ) async {
    final imageUrl = await _remoteDataSource.uploadStudentPhoto(
      studentId,
      imageBytes,
    );

    await _auditService.logUpdate(
      module: 'Students',
      recordId: studentId,
      description: 'Student profile photo uploaded',
      newValues: {'profileImageUrl': imageUrl},
    );

    return imageUrl;
  }

  Map<String, dynamic> _auditValues(StudentModel model) {
    final values = Map<String, dynamic>.from(model.toMap());
    values.remove('fatherCnic');
    values.remove('motherCnic');
    values.remove('guardianCnic');
    return values;
  }
}
