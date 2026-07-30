import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/teacher_model.dart';

abstract class TeacherRemoteDataSource {
  Future<List<TeacherModel>> getTeachers();
  Future<void> saveTeacher(TeacherModel teacher);
  Future<void> deleteTeacher(String id);
  String generateTeacherId();
}

class TeacherRemoteDataSourceImpl implements TeacherRemoteDataSource {
  TeacherRemoteDataSourceImpl({required FirebaseFirestoreService firestoreService}) : _firestoreService = firestoreService;
  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<TeacherModel>> getTeachers() async {
    final snapshot = await _firestoreService.collection(FirestorePaths.teachers).orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => TeacherModel.fromMap({...doc.data(), 'id': doc.id})).toList();
  }

  @override
  Future<void> saveTeacher(TeacherModel teacher) => _firestoreService.collection(FirestorePaths.teachers).doc(teacher.id).set(teacher.toMap());

  @override
  Future<void> deleteTeacher(String id) => _firestoreService.collection(FirestorePaths.teachers).doc(id).delete();

  @override
  String generateTeacherId() => _firestoreService.collection(FirestorePaths.teachers).doc().id;
}
