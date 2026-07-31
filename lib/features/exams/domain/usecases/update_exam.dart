import '../entities/exam_entity.dart';
import '../repositories/exam_repository.dart';
import 'create_exam.dart';

class UpdateExam {
  const UpdateExam(this._repository);

  final ExamRepository _repository;

  Future<void> call(ExamEntity exam) async {
    validateExam(exam);
    await _repository.updateExam(exam);
  }
}
