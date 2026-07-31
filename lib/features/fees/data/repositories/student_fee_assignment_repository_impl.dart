import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/student_fee_assignment_entity.dart';
import '../../domain/repositories/student_fee_assignment_repository.dart';
import '../models/student_fee_assignment_model.dart';

class StudentFeeAssignmentRepositoryImpl
    implements StudentFeeAssignmentRepository {
  const StudentFeeAssignmentRepositoryImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<StudentFeeAssignmentEntity>> getAssignments({
    String? academicSession,
    String? studentId,
    bool? isActive,
  }) async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.studentFeeAssignments)
        .get();

    final values =
        snapshot.docs
            .map(
              (document) => StudentFeeAssignmentModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .where(
              (item) =>
                  (academicSession == null ||
                      item.academicSession == academicSession) &&
                  (studentId == null || item.studentId == studentId) &&
                  (isActive == null || item.isActive == isActive),
            )
            .toList()
          ..sort((a, b) => a.studentName.compareTo(b.studentName));

    return List<StudentFeeAssignmentEntity>.unmodifiable(values);
  }

  @override
  Future<void> saveAssignment(StudentFeeAssignmentEntity assignment) async {
    final existing = await getAssignments(
      academicSession: assignment.academicSession,
      studentId: assignment.studentId,
    );

    if (existing.any((item) => item.id != assignment.id)) {
      throw StateError(
        'This student already has a fee assignment for '
        '${assignment.academicSession}.',
      );
    }

    await _firestoreService
        .collection(FirestorePaths.studentFeeAssignments)
        .doc(assignment.id)
        .set(StudentFeeAssignmentModel.fromEntity(assignment).toMap());
  }

  @override
  Future<void> deleteAssignment(String id) {
    return _firestoreService
        .collection(FirestorePaths.studentFeeAssignments)
        .doc(id)
        .delete();
  }

  @override
  String generateId() {
    return _firestoreService
        .collection(FirestorePaths.studentFeeAssignments)
        .doc()
        .id;
  }
}
