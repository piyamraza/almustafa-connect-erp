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
          ..sort((a, b) {
            if (a.userId == b.userId && a.isPrimary != b.isPrimary) {
              return a.isPrimary ? -1 : 1;
            }

            return a.userName.toLowerCase().compareTo(b.userName.toLowerCase());
          });

    return List.unmodifiable(values);
  }

  @override
  Future<List<UserRoleAssignmentEntity>> getAssignmentsByUserId(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return const [];

    // Role documents are canonicalised as user_roles/{authUid}. Reading the
    // entire collection fails for teacher/parent accounts under production
    // Firestore rules, which previously made them fall through to Admin UI.
    final document = await _service
        .collection(FirestorePaths.userRoleAssignments)
        .doc(normalizedUserId)
        .get();
    if (!document.exists) {
      // Accounts created by older releases stored assignments under a random
      // document id. Keep those users working while all new writes remain
      // canonical at user_roles/{authUid}.
      final legacySnapshot = await _service
          .collection(FirestorePaths.userRoleAssignments)
          .where('userId', isEqualTo: normalizedUserId)
          .get();

      return legacySnapshot.docs
          .map(
            (doc) => UserRoleAssignmentModel.fromMap({
              ...doc.data(),
              'id': doc.id,
            }),
          )
          .where((assignment) => assignment.userId == normalizedUserId)
          .toList(growable: false);
    }

    final assignment = UserRoleAssignmentModel.fromMap({
      ...?document.data(),
      'id': document.id,
    });
    if (assignment.userId.isNotEmpty &&
        assignment.userId != normalizedUserId) {
      return const [];
    }
    return [assignment];
  }

  @override
  Future<UserRoleAssignmentEntity?> getAssignmentByUserId(String userId) async {
    final assignments = await getAssignmentsByUserId(userId);

    if (assignments.isEmpty) {
      return null;
    }

    for (final assignment in assignments) {
      if (assignment.isPrimary) {
        return assignment;
      }
    }

    return assignments.first;
  }

  @override
  Future<void> saveAssignment(UserRoleAssignmentEntity assignment) async {
    final userId = assignment.userId.trim();
    final email = assignment.email.trim();
    final roleId = assignment.roleId.trim();

    if (userId.isEmpty) {
      throw StateError('Firebase Auth UID is required.');
    }

    if (email.isEmpty) {
      throw StateError('User email is required.');
    }

    if (roleId.isEmpty) {
      throw StateError('Select a role.');
    }

    if (assignment.validFrom != null &&
        assignment.validUntil != null &&
        assignment.validUntil!.isBefore(assignment.validFrom!)) {
      throw StateError('Role expiry date cannot be before the start date.');
    }

    final existing = await getAssignmentsByUserId(userId);

    final duplicateRole = existing.any(
      (item) => item.roleId == roleId && item.id != assignment.id,
    );

    if (duplicateRole) {
      throw StateError('This user already has this role assigned.');
    }

    if (assignment.isPrimary) {
      for (final item in existing.where(
        (value) => value.isPrimary && value.id != assignment.id,
      )) {
        await _service
            .collection(FirestorePaths.userRoleAssignments)
            .doc(item.id)
            .set(
              UserRoleAssignmentModel.fromEntity(
                item.copyWith(isPrimary: false, updatedAt: DateTime.now()),
              ).toMap(),
            );
      }
    }

    final documentId = assignment.id.trim().isEmpty
        ? generateId()
        : assignment.id.trim();

    final normalizedAssignment = UserRoleAssignmentEntity(
      id: documentId,
      userId: userId,
      userName: assignment.userName.trim(),
      email: email,
      roleId: roleId,
      roleName: assignment.roleName.trim(),
      branchId: assignment.branchId.trim().isEmpty
          ? 'main'
          : assignment.branchId.trim(),
      isActive: assignment.isActive,
      isPrimary: assignment.isPrimary,
      validFrom: assignment.validFrom,
      validUntil: assignment.validUntil,
      assignedBy: assignment.assignedBy.trim(),
      assignedAt: assignment.assignedAt,
      updatedAt: DateTime.now(),
    );

    await _service
        .collection(FirestorePaths.userRoleAssignments)
        .doc(documentId)
        .set(UserRoleAssignmentModel.fromEntity(normalizedAssignment).toMap());
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
