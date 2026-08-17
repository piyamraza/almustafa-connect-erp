import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/exam_seating_entities.dart';
import '../../domain/repositories/exam_seating_repository.dart';
import '../models/exam_seating_models.dart';

class ExamSeatingRepositoryImpl implements ExamSeatingRepository {
  const ExamSeatingRepositoryImpl(this._service);
  final FirebaseFirestoreService _service;

  @override
  Future<ExamRoomSetupEntity?> getRoomSetup(String examId) async {
    final doc = await _service
        .collection(FirestorePaths.examRoomSetups)
        .doc(examId)
        .get();
    final data = doc.data();
    return !doc.exists || data == null ? null : roomSetupFromMap(data);
  }

  @override
  Future<void> saveRoomSetup(ExamRoomSetupEntity setup) => _service
      .collection(FirestorePaths.examRoomSetups)
      .doc(setup.examId)
      .set(roomSetupToMap(setup));

  @override
  Future<List<DailyExamPlanEntity>> getPlans({String? examId}) async {
    final snapshot = await _service
        .collection(FirestorePaths.examDailyPlans)
        .get();
    final values =
        snapshot.docs
            .map((doc) => planFromMap(doc.id, doc.data()))
            .where((plan) => examId == null || plan.examId == examId)
            .toList()
          ..sort((a, b) => b.examDate.compareTo(a.examDate));
    return List.unmodifiable(values);
  }

  @override
  Future<void> savePlan(DailyExamPlanEntity plan) => _service
      .collection(FirestorePaths.examDailyPlans)
      .doc(plan.id)
      .set(planToMap(plan));

  @override
  String generatePlanId() =>
      _service.collection(FirestorePaths.examDailyPlans).doc().id;
}
