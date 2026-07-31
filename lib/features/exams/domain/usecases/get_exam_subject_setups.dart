import '../entities/exam_subject_setup_entity.dart';
import '../repositories/exam_subject_setup_repository.dart';
class GetExamSubjectSetups { const GetExamSubjectSetups(this._repository); final ExamSubjectSetupRepository _repository; Future<List<ExamSubjectSetupEntity>> call()=>_repository.getSetups(); }
