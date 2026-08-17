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
    super.isPrimary,
    super.validFrom,
    super.validUntil,
    super.additionalRoleIds,
    super.linkedEntityType,
    super.linkedEntityId,
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
      isPrimary: value.isPrimary,
      validFrom: value.validFrom,
      validUntil: value.validUntil,
      additionalRoleIds: value.additionalRoleIds,
      linkedEntityType: value.linkedEntityType,
      linkedEntityId: value.linkedEntityId,
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
      isPrimary: map['isPrimary'] as bool? ?? false,
      validFrom: _nullableDate(map['validFrom']),
      validUntil: _nullableDate(map['validUntil']),
      additionalRoleIds: (map['roleIds'] as List? ?? const [])
          .map((value) => value.toString())
          .where((value) => value != (map['roleId'] as String? ?? ''))
          .toList(growable: false),
      linkedEntityType: map['linkedEntityType'] as String? ?? '',
      linkedEntityId: map['linkedEntityId'] as String? ?? '',
      assignedBy: map['assignedBy'] as String? ?? 'Admin',
      assignedAt: _date(map['assignedAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'email': email,
    'roleId': roleId,
    'roleName': roleName,
    'branchId': branchId,
    'isActive': isActive,
    'isPrimary': isPrimary,
    'validFrom': validFrom == null ? null : Timestamp.fromDate(validFrom!),
    'validUntil': validUntil == null ? null : Timestamp.fromDate(validUntil!),
    'roleIds': <String>{roleId, ...additionalRoleIds}.toList(),
    'linkedEntityType': linkedEntityType,
    'linkedEntityId': linkedEntityId,
    'assignedBy': assignedBy,
    'assignedAt': Timestamp.fromDate(assignedAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'schemaVersion': 2,
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return _date(value);
  }
}
