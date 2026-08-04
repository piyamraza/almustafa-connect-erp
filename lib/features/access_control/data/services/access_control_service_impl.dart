import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_permission.dart';
import '../../domain/entities/app_role_entity.dart';
import '../../domain/entities/user_role_assignment_entity.dart';
import '../../domain/repositories/app_role_repository.dart';
import '../../domain/repositories/user_role_assignment_repository.dart';
import '../../domain/services/access_control_service.dart';

class AccessControlServiceImpl extends AccessControlService {
  AccessControlServiceImpl(
    this._auth,
    this._assignmentRepository,
    this._roleRepository,
  );

  final FirebaseAuth _auth;
  final UserRoleAssignmentRepository _assignmentRepository;
  final AppRoleRepository _roleRepository;

  bool _isLoaded = false;
  bool _isLoading = false;
  bool _isBootstrapAccess = false;

  List<UserRoleAssignmentEntity> _assignments = const [];
  List<AppRoleEntity> _roles = const [];
  Set<AppPermission> _permissions = const {};

  String? _errorMessage;

  @override
  bool get isLoaded => _isLoaded;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isAuthenticated => _auth.currentUser != null;

  @override
  bool get isBootstrapAccess => _isBootstrapAccess;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  String? get currentUserEmail => _auth.currentUser?.email;

  @override
  List<UserRoleAssignmentEntity> get assignments =>
      List.unmodifiable(_assignments);

  @override
  UserRoleAssignmentEntity? get assignment {
    for (final item in _assignments) {
      if (item.isPrimary) {
        return item;
      }
    }

    if (_assignments.isEmpty) {
      return null;
    }

    return _assignments.first;
  }

  @override
  List<AppRoleEntity> get roles => List.unmodifiable(_roles);

  @override
  AppRoleEntity? get role {
    final primaryAssignment = assignment;

    if (primaryAssignment != null) {
      for (final item in _roles) {
        if (item.id == primaryAssignment.roleId) {
          return item;
        }
      }
    }

    if (_roles.isEmpty) {
      return null;
    }

    return _roles.first;
  }

  @override
  Set<AppPermission> get permissions => Set.unmodifiable(_permissions);

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool hasPermission(AppPermission permission) {
    if (!_isLoaded || !isAuthenticated) {
      return false;
    }

    if (_isBootstrapAccess) {
      return true;
    }

    return _permissions.contains(permission);
  }

  @override
  bool hasAnyPermission(Iterable<AppPermission> permissions) {
    return permissions.any(hasPermission);
  }

  @override
  bool hasAllPermissions(Iterable<AppPermission> permissions) {
    return permissions.every(hasPermission);
  }

  @override
  bool hasRole(String roleIdOrName) {
    if (!_isLoaded || !isAuthenticated) {
      return false;
    }

    if (_isBootstrapAccess) {
      return true;
    }

    final value = roleIdOrName.trim().toLowerCase();

    if (value.isEmpty) {
      return false;
    }

    return _roles.any(
      (item) =>
          item.id.trim().toLowerCase() == value ||
          item.name.trim().toLowerCase() == value,
    );
  }

  @override
  Future<void> loadCurrentAccess({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }

    if (_isLoaded && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;

      if (user == null) {
        _assignments = const [];
        _roles = const [];
        _permissions = const {};
        _isBootstrapAccess = false;
        _isLoaded = true;
        return;
      }

      final allAssignments = await _assignmentRepository.getAssignmentsByUserId(
        user.uid,
      );

      final now = DateTime.now();

      final activeAssignments =
          allAssignments.where((item) => item.isValidAt(now)).toList()..sort((
            a,
            b,
          ) {
            if (a.isPrimary != b.isPrimary) {
              return a.isPrimary ? -1 : 1;
            }

            return a.roleName.toLowerCase().compareTo(b.roleName.toLowerCase());
          });

      _assignments = List.unmodifiable(activeAssignments);

      if (_assignments.isEmpty) {
        _roles = const [];
        _permissions = const {};

        // Safe migration mode:
        // If the existing administrator has no assignment yet,
        // allow access so the first roles can be configured.
        _isBootstrapAccess = true;
        _isLoaded = true;
        return;
      }

      _isBootstrapAccess = false;

      final availableRoles = await _roleRepository.getRoles();

      final assignedRoleIds = _assignments.map((item) => item.roleId).toSet();

      final activeRoles = availableRoles
          .where((item) => item.isActive && assignedRoleIds.contains(item.id))
          .toList();

      activeRoles.sort((a, b) {
        final primaryRoleId = assignment?.roleId;

        if (a.id == primaryRoleId && b.id != primaryRoleId) {
          return -1;
        }

        if (b.id == primaryRoleId && a.id != primaryRoleId) {
          return 1;
        }

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      _roles = List.unmodifiable(activeRoles);

      final mergedPermissions = <AppPermission>{};

      for (final item in _roles) {
        mergedPermissions.addAll(item.permissions);
      }

      _permissions = Set.unmodifiable(mergedPermissions);

      final missingRoleIds = assignedRoleIds
          .where((roleId) => !_roles.any((role) => role.id == roleId))
          .toList();

      if (missingRoleIds.isNotEmpty) {
        _errorMessage =
            'One or more assigned roles no longer exist or are inactive.';
      }

      _isLoaded = true;
    } catch (error) {
      _assignments = const [];
      _roles = const [];
      _permissions = const {};
      _isBootstrapAccess = false;
      _isLoaded = true;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> clear() async {
    _isLoaded = false;
    _isLoading = false;
    _isBootstrapAccess = false;

    _assignments = const [];
    _roles = const [];
    _permissions = const {};

    _errorMessage = null;

    notifyListeners();
  }
}
