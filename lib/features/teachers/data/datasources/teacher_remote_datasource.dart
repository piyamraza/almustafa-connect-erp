import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/teacher_model.dart';

abstract class TeacherRemoteDataSource {
  Future<List<TeacherModel>> getTeachers();

  Future<TeacherModel?> getTeacherById(String id);

  Future<void> saveTeacher(TeacherModel teacher);

  Future<void> deleteTeacher(String id);

  String generateTeacherId();
}

class TeacherRemoteDataSourceImpl implements TeacherRemoteDataSource {
  TeacherRemoteDataSourceImpl({required this._firestoreService});

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<TeacherModel>> getTeachers() async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.teachers)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (document) =>
              TeacherModel.fromMap({...document.data(), 'id': document.id}),
        )
        .toList(growable: false);
  }

  @override
  Future<TeacherModel?> getTeacherById(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return null;

    final snapshot = await _firestoreService
        .collection(FirestorePaths.teachers)
        .doc(normalizedId)
        .get();

    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;

    return TeacherModel.fromMap({...data, 'id': snapshot.id});
  }

  @override
  Future<void> saveTeacher(TeacherModel teacher) {
    return _firestoreService
        .collection(FirestorePaths.teachers)
        .doc(teacher.id)
        .set(teacher.toMap());
  }

  @override
  Future<void> deleteTeacher(String id) {
    return _firestoreService
        .collection(FirestorePaths.teachers)
        .doc(id)
        .delete();
  }

  @override
  String generateTeacherId() {
    return _firestoreService.collection(FirestorePaths.teachers).doc().id;
  }
}
