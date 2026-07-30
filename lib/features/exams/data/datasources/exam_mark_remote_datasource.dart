import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/exam_mark_model.dart';

class ExamMarkRemoteDataSource {
  ExamMarkRemoteDataSource({required FirebaseFirestoreService firestoreService}) : _service = firestoreService;
  final FirebaseFirestoreService _service;
  Future<void> save(ExamMarkModel mark) => _service.collection(FirestorePaths.examMarks).doc(mark.id).set(mark.toMap());
}
