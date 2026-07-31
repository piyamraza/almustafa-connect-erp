import '../entities/exam_subject_setup_entity.dart';
import '../repositories/exam_subject_setup_repository.dart';

class GetExamSubjectSetupsForExam {
  GetExamSubjectSetupsForExam(this._repository);

  final ExamSubjectSetupRepository _repository;

  Future<List<ExamSubjectSetupEntity>> call(String examId) {
    return _repository.getSetupsForExam(examId);
  }
}
