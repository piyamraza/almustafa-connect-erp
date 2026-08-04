import '../entities/user_role_assignment_entity.dart';

abstract class UserRoleAssignmentRepository {
  Future<List<UserRoleAssignmentEntity>> getAssignments({
    String? roleId,
    bool? isActive,
    String? searchText,
  });

  /// Returns all role assignments of a user.
  Future<List<UserRoleAssignmentEntity>> getAssignmentsByUserId(String userId);

  /// Returns the primary role assignment.
  Future<UserRoleAssignmentEntity?> getAssignmentByUserId(String userId);

  Future<void> saveAssignment(UserRoleAssignmentEntity assignment);

  Future<void> deleteAssignment(String id);

  String generateId();
}
