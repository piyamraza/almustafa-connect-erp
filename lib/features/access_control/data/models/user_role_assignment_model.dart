import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_role_assignment_entity.dart';

class UserRoleAssignmentModel extends UserRoleAssignmentEntity {
  const UserRoleAssignmentModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.email,
    required super.roleId,
    required super.roleName,
    required super.branchId,
    required super.isActive,
    required super.assignedBy,
    required super.assignedAt,
    required super.updatedAt,
  });

  factory UserRoleAssignmentModel.fromEntity(UserRoleAssignmentEntity value) {
    return UserRoleAssignmentModel(
      id: value.id,
      userId: value.userId,
      userName: value.userName,
      email: value.email,
      roleId: value.roleId,
      roleName: value.roleName,
      branchId: value.branchId,
      isActive: value.isActive,
      assignedBy: value.assignedBy,
      assignedAt: value.assignedAt,
      updatedAt: value.updatedAt,
    );
  }

  factory UserRoleAssignmentModel.fromMap(Map<String, dynamic> map) {
    return UserRoleAssignmentModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      roleId: map['roleId'] as String? ?? '',
      roleName: map['roleName'] as String? ?? '',
      branchId: map['branchId'] as String? ?? 'main',
      isActive: map['isActive'] as bool? ?? true,
      assignedBy: map['assignedBy'] as String? ?? 'Admin',
      assignedAt: _date(map['assignedAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'email': email,
    'roleId': roleId,
    'roleName': roleName,
    'branchId': branchId,
    'isActive': isActive,
    'assignedBy': assignedBy,
    'assignedAt': Timestamp.fromDate(assignedAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
