import 'package:flutter/foundation.dart';

import '../entities/app_permission.dart';
import '../entities/app_role_entity.dart';
import '../entities/user_role_assignment_entity.dart';

abstract class AccessControlService extends ChangeNotifier {
  bool get isLoaded;
  bool get isLoading;
  bool get isAuthenticated;
  bool get isBootstrapAccess;
  String? get currentUserId;
  String? get currentUserEmail;
  UserRoleAssignmentEntity? get assignment;
  AppRoleEntity? get role;
  String? get errorMessage;

  bool hasPermission(AppPermission permission);
  bool hasAnyPermission(Iterable<AppPermission> permissions);
  bool hasAllPermissions(Iterable<AppPermission> permissions);

  Future<void> loadCurrentAccess({bool forceRefresh = false});
  Future<void> clear();
}
