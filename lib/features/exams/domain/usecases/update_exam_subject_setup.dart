import '../entities/exam_subject_setup_entity.dart';
import '../repositories/exam_subject_setup_repository.dart';
import 'create_exam_subject_setups.dart';
class UpdateExamSubjectSetup { const UpdateExamSubjectSetup(this._repository); final ExamSubjectSetupRepository _repository; Future<void> call(ExamSubjectSetupEntity setup) async {validateExamSubjectSetup(setup);await _repository.updateSetup(setup);} }
