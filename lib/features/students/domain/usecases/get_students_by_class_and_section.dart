import '../entities/student_entity.dart';
import '../repositories/student_repository.dart';

class GetStudentsByClassAndSection {
  GetStudentsByClassAndSection(this._repository);

  final StudentRepository _repository;

  Future<List<StudentEntity>> call({
    required String classId,
    required String sectionId,
  }) {
    return _repository.getStudentsByClassAndSection(
      classId: classId,
      sectionId: sectionId,
    );
  }
}
