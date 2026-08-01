import 'package:equatable/equatable.dart';

class UserAccountEntity extends Equatable {
  const UserAccountEntity({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    required this.disabled,
    required this.emailVerified,
    required this.roleId,
    required this.roleName,
    required this.branchId,
    required this.linkedEntityType,
    required this.linkedEntityId,
    required this.isActive,
    required this.createdAt,
    required this.lastSignInAt,
  });

  final String uid;
  final String email;
  final String username;
  final String displayName;
  final bool disabled;
  final bool emailVerified;
  final String roleId;
  final String roleName;
  final String branchId;
  final String linkedEntityType;
  final String linkedEntityId;
  final bool isActive;
  final String createdAt;
  final String lastSignInAt;

  factory UserAccountEntity.fromMap(Map<String, dynamic> map) {
    return UserAccountEntity(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      disabled: map['disabled'] == true,
      emailVerified: map['emailVerified'] == true,
      roleId: map['roleId']?.toString() ?? '',
      roleName: map['roleName']?.toString() ?? 'Not Assigned',
      branchId: map['branchId']?.toString() ?? 'main',
      linkedEntityType: map['linkedEntityType']?.toString() ?? '',
      linkedEntityId: map['linkedEntityId']?.toString() ?? '',
      isActive: map['isActive'] != false,
      createdAt: map['createdAt']?.toString() ?? '',
      lastSignInAt: map['lastSignInAt']?.toString() ?? '',
    );
  }

  @override
  List<Object> get props => [
    uid,
    email,
    username,
    displayName,
    disabled,
    emailVerified,
    roleId,
    roleName,
    branchId,
    linkedEntityType,
    linkedEntityId,
    isActive,
    createdAt,
    lastSignInAt,
  ];
}
