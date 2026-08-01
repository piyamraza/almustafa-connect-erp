import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_permission.dart';
import '../../domain/entities/app_role_entity.dart';

class AppRoleModel extends AppRoleEntity {
  AppRoleModel({
    required super.id,
    required super.name,
    required super.description,
    required super.permissions,
    required super.isSystemRole,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AppRoleModel.fromEntity(AppRoleEntity value) {
    return AppRoleModel(
      id: value.id,
      name: value.name,
      description: value.description,
      permissions: value.permissions,
      isSystemRole: value.isSystemRole,
      isActive: value.isActive,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

  factory AppRoleModel.fromMap(Map<String, dynamic> map) {
    final rawPermissions = map['permissions'] as List<dynamic>? ?? const [];

    return AppRoleModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      permissions: rawPermissions
          .map((value) => value.toString())
          .map(
            (name) => AppPermission.values.where(
              (permission) => permission.name == name,
            ),
          )
          .where((matches) => matches.isNotEmpty)
          .map((matches) => matches.first)
          .toList(growable: false),
      isSystemRole: map['isSystemRole'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'permissions': permissions
        .map((permission) => permission.name)
        .toList(growable: false),
    'isSystemRole': isSystemRole,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
