import '../entities/exam_entity.dart';
import '../repositories/exam_repository.dart';

class GetExams {
  const GetExams(this._repository);

  final ExamRepository _repository;

  Future<List<ExamEntity>> call({
    String? academicSession,
    bool? isActive,
  }) {
    return _repository.getExams(
      academicSession: academicSession,
      isActive: isActive,
    );
  }
}
