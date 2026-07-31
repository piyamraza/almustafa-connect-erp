import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/teacher_availability_entity.dart';
import '../../domain/repositories/teacher_availability_repository.dart';
import '../models/teacher_availability_model.dart';

class TeacherAvailabilityRepositoryImpl
    implements TeacherAvailabilityRepository {
  const TeacherAvailabilityRepositoryImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<TeacherAvailabilityEntity>> getAvailabilities({
    required String branchId,
    required String academicSession,
  }) async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.teacherAvailabilities)
        .where('branchId', isEqualTo: branchId.trim())
        .where('academicSession', isEqualTo: academicSession.trim())
        .get();

    final values =
        snapshot.docs
            .map(
              (document) => TeacherAvailabilityModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .toList()
          ..sort(
            (first, second) => first.teacherName.compareTo(second.teacherName),
          );

    return List<TeacherAvailabilityEntity>.unmodifiable(values);
  }

  @override
  Future<void> saveAvailability(TeacherAvailabilityEntity availability) {
    return _firestoreService
        .collection(FirestorePaths.teacherAvailabilities)
        .doc(availability.id)
        .set(TeacherAvailabilityModel.fromEntity(availability).toMap());
  }

  @override
  Future<void> deleteAvailability(String id) {
    return _firestoreService
        .collection(FirestorePaths.teacherAvailabilities)
        .doc(id)
        .delete();
  }

  @override
  String generateId() {
    return _firestoreService
        .collection(FirestorePaths.teacherAvailabilities)
        .doc()
        .id;
  }
}
