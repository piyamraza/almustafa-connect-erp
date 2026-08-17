import '../entities/admission_test_entities.dart';

abstract class AdmissionTestRepository {
  Future<List<AdmissionQuestionEntity>> getQuestions();
  Future<void> saveQuestion(AdmissionQuestionEntity value);
  Future<void> deleteQuestion(String id);
  Future<List<AdmissionPaperTemplateEntity>> getTemplates();
  Future<void> saveTemplate(AdmissionPaperTemplateEntity value);
  Future<List<AdmissionPaperEntity>> getPapers();
  Future<void> savePaper(AdmissionPaperEntity value);
  Future<List<AdmissionCandidateEntity>> getCandidates();
  Future<void> saveCandidate(AdmissionCandidateEntity value);
  String newId(String collection);
}
