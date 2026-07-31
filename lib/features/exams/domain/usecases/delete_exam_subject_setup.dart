import '../repositories/exam_subject_setup_repository.dart';
class DeleteExamSubjectSetup { const DeleteExamSubjectSetup(this._repository); final ExamSubjectSetupRepository _repository; Future<void> call(String id){if(id.trim().isEmpty)throw ArgumentError('Setup ID is required.');return _repository.deleteSetup(id.trim());} }
