import '../entities/student_entity.dart';
import '../repositories/student_repository.dart';

class GetStudentById {
  const GetStudentById(this._repository);

  final StudentRepository _repository;

  Future<StudentEntity?> call(String id) => _repository.getStudentById(id);
}
