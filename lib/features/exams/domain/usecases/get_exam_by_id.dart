import '../entities/exam_entity.dart';
import '../repositories/exam_repository.dart';

class GetExamById {
  const GetExamById(this._repository);

  final ExamRepository _repository;

  Future<ExamEntity?> call(String id) => _repository.getExamById(id);
}
