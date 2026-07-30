import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/teacher_assignment_model.dart';
abstract class TeacherAssignmentRemoteDataSource { Future<List<TeacherAssignmentModel>> getAssignments(); Future<void> saveAssignment(TeacherAssignmentModel assignment); Future<void> deleteAssignment(String id); String generateId(); }
class TeacherAssignmentRemoteDataSourceImpl implements TeacherAssignmentRemoteDataSource { TeacherAssignmentRemoteDataSourceImpl({required FirebaseFirestoreService firestoreService}) : _firestoreService = firestoreService; final FirebaseFirestoreService _firestoreService;
  @override Future<List<TeacherAssignmentModel>> getAssignments() async { final data = await _firestoreService.collection(FirestorePaths.teacherAssignments).orderBy('createdAt', descending: true).get(); return data.docs.map((doc) => TeacherAssignmentModel.fromMap({...doc.data(), 'id': doc.id})).toList(); }
  @override Future<void> saveAssignment(TeacherAssignmentModel assignment) => _firestoreService.collection(FirestorePaths.teacherAssignments).doc(assignment.id).set(assignment.toMap());
  @override Future<void> deleteAssignment(String id) => _firestoreService.collection(FirestorePaths.teacherAssignments).doc(id).delete();
  @override String generateId() => _firestoreService.collection(FirestorePaths.teacherAssignments).doc().id;
}
