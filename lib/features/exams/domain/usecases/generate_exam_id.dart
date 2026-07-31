import '../repositories/exam_repository.dart';

class GenerateExamId {
  const GenerateExamId(this._repository);

  final ExamRepository _repository;

  String call() => _repository.generateId();
}
