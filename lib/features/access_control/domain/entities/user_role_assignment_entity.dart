import 'package:equatable/equatable.dart';

class UserRoleAssignmentEntity extends Equatable {
  const UserRoleAssignmentEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.email,
    required this.roleId,
    required this.roleName,
    required this.branchId,
    required this.isActive,
    required this.assignedBy,
    required this.assignedAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String email;
  final String roleId;
  final String roleName;
  final String branchId;
  final bool isActive;
  final String assignedBy;
  final DateTime assignedAt;
  final DateTime updatedAt;

  UserRoleAssignmentEntity copyWith({
    String? userName,
    String? email,
    String? roleId,
    String? roleName,
    String? branchId,
    bool? isActive,
    String? assignedBy,
    DateTime? updatedAt,
  }) {
    return UserRoleAssignmentEntity(
      id: id,
      userId: userId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      branchId: branchId ?? this.branchId,
      isActive: isActive ?? this.isActive,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    userId,
    userName,
    email,
    roleId,
    roleName,
    branchId,
    isActive,
    assignedBy,
    assignedAt,
    updatedAt,
  ];
}
