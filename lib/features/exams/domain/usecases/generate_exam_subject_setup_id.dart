import '../repositories/exam_subject_setup_repository.dart';
class GenerateExamSubjectSetupId { const GenerateExamSubjectSetupId(this._repository); final ExamSubjectSetupRepository _repository; String call()=>_repository.generateId(); }
