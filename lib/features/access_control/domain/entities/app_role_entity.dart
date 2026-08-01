import 'package:equatable/equatable.dart';

import 'app_permission.dart';

class AppRoleEntity extends Equatable {
  AppRoleEntity({
    required this.id,
    required this.name,
    required this.description,
    required List<AppPermission> permissions,
    required this.isSystemRole,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : permissions = List<AppPermission>.unmodifiable(permissions);

  final String id;
  final String name;
  final String description;
  final List<AppPermission> permissions;
  final bool isSystemRole;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool allows(AppPermission permission) => permissions.contains(permission);

  AppRoleEntity copyWith({
    String? name,
    String? description,
    List<AppPermission>? permissions,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return AppRoleEntity(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      isSystemRole: isSystemRole,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    name,
    description,
    permissions,
    isSystemRole,
    isActive,
    updatedAt,
  ];
}
