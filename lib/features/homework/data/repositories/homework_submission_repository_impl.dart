import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/homework_submission_entity.dart';
import '../../domain/repositories/homework_submission_repository.dart';
import '../models/homework_submission_model.dart';

class HomeworkSubmissionRepositoryImpl implements HomeworkSubmissionRepository {
  const HomeworkSubmissionRepositoryImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<HomeworkSubmissionEntity>> getSubmissions({
    String? homeworkId,
    String? studentId,
    String? classId,
    String? sectionId,
    HomeworkSubmissionStatus? status,
  }) async {
    final snapshot = await _service
        .collection(FirestorePaths.homeworkSubmissions)
        .get();

    final values =
        snapshot.docs
            .map(
              (doc) => HomeworkSubmissionModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }),
            )
            .where(
              (item) =>
                  (homeworkId == null || item.homeworkId == homeworkId) &&
                  (studentId == null || item.studentId == studentId) &&
                  (classId == null || item.classId == classId) &&
                  (sectionId == null || item.sectionId == sectionId) &&
                  (status == null || item.status == status),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return List.unmodifiable(values);
  }

  @override
  Future<void> saveSubmission(HomeworkSubmissionEntity submission) async {
    await _service
        .collection(FirestorePaths.homeworkSubmissions)
        .doc(submission.id)
        .set(HomeworkSubmissionModel.fromEntity(submission).toMap());
  }

  @override
  Future<void> deleteSubmission(String id) {
    return _service
        .collection(FirestorePaths.homeworkSubmissions)
        .doc(id)
        .delete();
  }

  @override
  String generateId() {
    return _service.collection(FirestorePaths.homeworkSubmissions).doc().id;
  }
}
