import '../entities/exam_subject_setup_entity.dart';
abstract class ExamSubjectSetupRepository {
  Future<List<ExamSubjectSetupEntity>> getSetups();
  Future<List<ExamSubjectSetupEntity>> getSetupsForExam(String examId);
  Future<void> createSetups(List<ExamSubjectSetupEntity> setups);
  Future<void> updateSetup(ExamSubjectSetupEntity setup);
  Future<void> deleteSetup(String id);
  String generateId();
}
