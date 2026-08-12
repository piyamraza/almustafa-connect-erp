import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/teacher_assignment_model.dart';

abstract class TeacherAssignmentRemoteDataSource {
  Future<List<TeacherAssignmentModel>> getAssignments();
  Future<List<TeacherAssignmentModel>> getAssignmentsForTeacher(
    String teacherId,
  );
  Future<void> saveAssignment(TeacherAssignmentModel assignment);
  Future<void> deleteAssignment(String id);
  String generateId();
}

class TeacherAssignmentRemoteDataSourceImpl
    implements TeacherAssignmentRemoteDataSource {
  TeacherAssignmentRemoteDataSourceImpl({
    required this._firestoreService,
  });

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<TeacherAssignmentModel>> getAssignments() async {
    final data = await _firestoreService
        .collection(FirestorePaths.teacherAssignments)
        .orderBy('createdAt', descending: true)
        .get();
    return data.docs
        .map(
          (doc) => TeacherAssignmentModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList(growable: false);
  }

  @override
  Future<List<TeacherAssignmentModel>> getAssignmentsForTeacher(
    String teacherId,
  ) async {
    final normalizedId = teacherId.trim();
    if (normalizedId.isEmpty) return const [];
    final data = await _firestoreService
        .collection(FirestorePaths.teacherAssignments)
        .where('teacherId', isEqualTo: normalizedId)
        .get();
    return data.docs
        .map(
          (doc) => TeacherAssignmentModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveAssignment(TeacherAssignmentModel assignment) async {
    final assignments = await getAssignments();
    TeacherAssignmentModel? subjectAssignment;
    for (final value in assignments) {
      if (value.id != assignment.id &&
          value.assignmentKey == assignment.assignmentKey) {
        subjectAssignment = value;
        break;
      }
    }
    if (subjectAssignment != null) {
      throw StateError(
        '${assignment.subject} is already assigned to '
        '${subjectAssignment.teacherName} for '
        '${assignment.classId}-${assignment.sectionId} '
        'in ${assignment.academicSession}.',
      );
    }

    if (assignment.isClassTeacher) {
      TeacherAssignmentModel? classTeacherAssignment;
      for (final value in assignments) {
        if (value.id != assignment.id &&
            value.isClassTeacher &&
            value.classTeacherKey == assignment.classTeacherKey) {
          classTeacherAssignment = value;
          break;
        }
      }
      if (classTeacherAssignment != null) {
        throw StateError(
          '${classTeacherAssignment.teacherName} is already the class teacher '
          'for ${assignment.classId}-${assignment.sectionId} '
          'in ${assignment.academicSession}.',
        );
      }
    }

    await _firestoreService
        .collection(FirestorePaths.teacherAssignments)
        .doc(assignment.id)
        .set(assignment.toMap());
  }

  @override
  Future<void> deleteAssignment(String id) => _firestoreService
      .collection(FirestorePaths.teacherAssignments)
      .doc(id)
      .delete();

  @override
  String generateId() =>
      _firestoreService.collection(FirestorePaths.teacherAssignments).doc().id;
}
