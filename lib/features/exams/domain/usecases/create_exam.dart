import '../entities/exam_entity.dart';
import '../repositories/exam_repository.dart';

class CreateExam {
  const CreateExam(this._repository);

  final ExamRepository _repository;

  Future<void> call(ExamEntity exam) async {
    validateExam(exam);
    await _repository.createExam(exam);
  }
}

void validateExam(ExamEntity exam) {
  if (exam.id.trim().isEmpty) {
    throw ArgumentError.value(exam.id, 'exam.id', 'Exam ID cannot be empty.');
  }
  if (exam.name.trim().isEmpty) {
    throw ArgumentError.value(exam.name, 'exam.name', 'Exam name is required.');
  }
  if (exam.academicSession.trim().isEmpty) {
    throw ArgumentError.value(
      exam.academicSession,
      'exam.academicSession',
      'Academic session is required.',
    );
  }
  final hasSubjectSetup =
      exam.classId.trim().isNotEmpty ||
      exam.sectionId.trim().isNotEmpty ||
      exam.subject.trim().isNotEmpty ||
      exam.totalMarks > 0 ||
      exam.passingMarks > 0;
  if (hasSubjectSetup) {
    if (exam.classId.trim().isEmpty ||
        exam.sectionId.trim().isEmpty ||
        exam.subject.trim().isEmpty) {
      throw ArgumentError(
        'Class, section, and subject are required when marks are configured.',
      );
    }
    if (exam.totalMarks <= 0) {
      throw ArgumentError.value(
        exam.totalMarks,
        'exam.totalMarks',
        'Total marks must be greater than zero.',
      );
    }
    if (exam.passingMarks < 0 || exam.passingMarks > exam.totalMarks) {
      throw ArgumentError.value(
        exam.passingMarks,
        'exam.passingMarks',
        'Passing marks must be between zero and total marks.',
      );
    }
  }
  if (exam.startDate != null && exam.endDate != null &&
      exam.endDate!.isBefore(exam.startDate!)) {
    throw ArgumentError('Exam end date cannot be before its start date.');
  }
}
