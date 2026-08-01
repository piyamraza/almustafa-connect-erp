import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/user_role_assignment_entity.dart';
import '../../domain/repositories/user_role_assignment_repository.dart';
import '../models/user_role_assignment_model.dart';

class UserRoleAssignmentRepositoryImpl implements UserRoleAssignmentRepository {
  const UserRoleAssignmentRepositoryImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<UserRoleAssignmentEntity>> getAssignments({
    String? roleId,
    bool? isActive,
    String? searchText,
  }) async {
    final snapshot = await _service
        .collection(FirestorePaths.userRoleAssignments)
        .get();

    final query = searchText?.trim().toLowerCase() ?? '';

    final values =
        snapshot.docs
            .map(
              (doc) => UserRoleAssignmentModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }),
            )
            .where(
              (item) =>
                  (roleId == null || item.roleId == roleId) &&
                  (isActive == null || item.isActive == isActive) &&
                  (query.isEmpty ||
                      item.userName.toLowerCase().contains(query) ||
                      item.email.toLowerCase().contains(query) ||
                      item.userId.toLowerCase().contains(query)),
            )
            .toList()
          ..sort(
            (a, b) =>
                a.userName.toLowerCase().compareTo(b.userName.toLowerCase()),
          );

    return List.unmodifiable(values);
  }

  @override
  Future<UserRoleAssignmentEntity?> getAssignmentByUserId(String userId) async {
    final assignments = await getAssignments();

    for (final assignment in assignments) {
      if (assignment.userId == userId) return assignment;
    }

    return null;
  }

  @override
  Future<void> saveAssignment(UserRoleAssignmentEntity assignment) async {
    if (assignment.userId.trim().isEmpty) {
      throw StateError('Firebase Auth UID is required.');
    }

    if (assignment.email.trim().isEmpty) {
      throw StateError('User email is required.');
    }

    if (assignment.roleId.trim().isEmpty) {
      throw StateError('Select a role.');
    }

    final existing = await getAssignmentByUserId(assignment.userId.trim());

    if (existing != null && existing.id != assignment.id) {
      throw StateError('This Firebase user already has a role assignment.');
    }

    await _service
        .collection(FirestorePaths.userRoleAssignments)
        .doc(assignment.userId.trim())
        .set(UserRoleAssignmentModel.fromEntity(assignment).toMap());
    if (assignment.id != assignment.userId.trim()) {
      await _service
          .collection(FirestorePaths.userRoleAssignments)
          .doc(assignment.id)
          .delete();
    }
  }

  @override
  Future<void> deleteAssignment(String id) {
    return _service
        .collection(FirestorePaths.userRoleAssignments)
        .doc(id)
        .delete();
  }

  @override
  String generateId() {
    return _service.collection(FirestorePaths.userRoleAssignments).doc().id;
  }
}
