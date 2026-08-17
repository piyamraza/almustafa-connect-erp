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
    this.isPrimary = false,
    this.validFrom,
    this.validUntil,
    this.additionalRoleIds = const [],
    this.linkedEntityType = '',
    this.linkedEntityId = '',
  });

  final String id;
  final String userId;
  final String userName;
  final String email;
  final String roleId;
  final String roleName;
  final String branchId;

  final bool isActive;
  final bool isPrimary;

  final DateTime? validFrom;
  final DateTime? validUntil;
  final List<String> additionalRoleIds;
  final String linkedEntityType;
  final String linkedEntityId;

  final String assignedBy;
  final DateTime assignedAt;
  final DateTime updatedAt;

  bool isValidAt(DateTime value) {
    if (!isActive) {
      return false;
    }

    final date = DateTime(value.year, value.month, value.day);

    final startDate = validFrom == null
        ? null
        : DateTime(validFrom!.year, validFrom!.month, validFrom!.day);

    final expiryDate = validUntil == null
        ? null
        : DateTime(validUntil!.year, validUntil!.month, validUntil!.day);

    if (startDate != null && date.isBefore(startDate)) {
      return false;
    }

    if (expiryDate != null && date.isAfter(expiryDate)) {
      return false;
    }

    return true;
  }

  UserRoleAssignmentEntity copyWith({
    String? userName,
    String? email,
    String? roleId,
    String? roleName,
    String? branchId,
    bool? isActive,
    bool? isPrimary,
    DateTime? validFrom,
    DateTime? validUntil,
    bool clearValidFrom = false,
    bool clearValidUntil = false,
    String? assignedBy,
    DateTime? updatedAt,
    String? linkedEntityType,
    String? linkedEntityId,
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
      isPrimary: isPrimary ?? this.isPrimary,
      validFrom: clearValidFrom ? null : validFrom ?? this.validFrom,
      validUntil: clearValidUntil ? null : validUntil ?? this.validUntil,
      additionalRoleIds: additionalRoleIds,
      linkedEntityType: linkedEntityType ?? this.linkedEntityType,
      linkedEntityId: linkedEntityId ?? this.linkedEntityId,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    email,
    roleId,
    roleName,
    branchId,
    isActive,
    isPrimary,
    validFrom,
    validUntil,
    additionalRoleIds,
    linkedEntityType,
    linkedEntityId,
    assignedBy,
    assignedAt,
    updatedAt,
  ];
}
