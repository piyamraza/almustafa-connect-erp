import '../entities/app_role_entity.dart';

abstract class AppRoleRepository {
  Future<List<AppRoleEntity>> getRoles();

  Future<void> saveRole(AppRoleEntity role);

  Future<void> deleteRole(String id);

  Future<void> seedDefaultRoles();

  String generateId();
}
