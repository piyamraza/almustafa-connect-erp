import '../entities/exam_subject_setup_entity.dart';
import '../repositories/exam_subject_setup_repository.dart';

class CreateExamSubjectSetups {
  const CreateExamSubjectSetups(this._repository);

  final ExamSubjectSetupRepository _repository;

  Future<void> call(List<ExamSubjectSetupEntity> setups) async {
    if (setups.isEmpty) {
      throw ArgumentError('Add at least one subject setup.');
    }

    final keys = <String>{};
    for (final setup in setups) {
      validateExamSubjectSetup(setup);
      if (!keys.add(setup.uniqueKey)) {
        throw ArgumentError('Duplicate subject setup selected.');
      }
    }

    await _repository.createSetups(setups);
  }
}

void validateExamSubjectSetup(ExamSubjectSetupEntity setup) {
  if (setup.examId.trim().isEmpty) {
    throw ArgumentError('Exam is required.');
  }
  if (setup.classId.trim().isEmpty) {
    throw ArgumentError('Class is required.');
  }
  if (setup.sectionId.trim().isEmpty) {
    throw ArgumentError('Section is required.');
  }
  if (setup.subjectId.trim().isEmpty) {
    throw ArgumentError('Subject is required.');
  }
  if (setup.totalMarks <= 0) {
    throw ArgumentError('Total marks must be greater than zero.');
  }
  if (setup.passingMarks < 0 || setup.passingMarks > setup.totalMarks) {
    throw ArgumentError('Passing marks must be between zero and total marks.');
  }
  if (!setup.isComponentDistributionValid) {
    throw ArgumentError(
      'Component marks for ${setup.subjectName} are invalid or '
      'do not equal the subject total.',
    );
  }
}
