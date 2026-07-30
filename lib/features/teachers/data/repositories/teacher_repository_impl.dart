import '../../domain/entities/teacher_entity.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/teacher_remote_datasource.dart';
import '../models/teacher_model.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  TeacherRepositoryImpl({required TeacherRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;
  final TeacherRemoteDataSource _remoteDataSource;
  @override Future<List<TeacherEntity>> getTeachers() => _remoteDataSource.getTeachers();
  @override Future<void> saveTeacher(TeacherEntity teacher) => _remoteDataSource.saveTeacher(TeacherModel.fromEntity(teacher));
  @override Future<void> deleteTeacher(String id) => _remoteDataSource.deleteTeacher(id);
  @override String generateTeacherId() => _remoteDataSource.generateTeacherId();
}
