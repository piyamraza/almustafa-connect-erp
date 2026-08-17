import '../entities/exam_seating_entities.dart';

abstract class ExamSeatingRepository {
  Future<ExamRoomSetupEntity?> getRoomSetup(String examId);
  Future<void> saveRoomSetup(ExamRoomSetupEntity setup);
  Future<List<DailyExamPlanEntity>> getPlans({String? examId});
  Future<void> savePlan(DailyExamPlanEntity plan);
  String generatePlanId();
}
