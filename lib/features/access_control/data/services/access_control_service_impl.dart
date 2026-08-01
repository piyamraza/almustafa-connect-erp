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
  UserRoleAssignmentEntity? _assignment;
  AppRoleEntity? _role;
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
  UserRoleAssignmentEntity? get assignment => _assignment;

  @override
  AppRoleEntity? get role => _role;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool hasPermission(AppPermission permission) {
    if (!_isLoaded || !isAuthenticated) return false;
    if (_isBootstrapAccess) return true;
    if (!(_assignment?.isActive ?? false)) return false;
    if (!(_role?.isActive ?? false)) return false;
    return _role?.allows(permission) ?? false;
  }

  @override
  bool hasAnyPermission(Iterable<AppPermission> permissions) =>
      permissions.any(hasPermission);

  @override
  bool hasAllPermissions(Iterable<AppPermission> permissions) =>
      permissions.every(hasPermission);

  @override
  Future<void> loadCurrentAccess({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_isLoaded && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;

      if (user == null) {
        _assignment = null;
        _role = null;
        _isBootstrapAccess = false;
        _isLoaded = true;
        return;
      }

      _assignment = await _assignmentRepository.getAssignmentByUserId(user.uid);

      if (_assignment == null) {
        // Safe migration mode: the existing administrator remains able
        // to configure the first user-role assignment.
        _role = null;
        _isBootstrapAccess = true;
        _isLoaded = true;
        return;
      }

      _isBootstrapAccess = false;
      final roles = await _roleRepository.getRoles();

      for (final item in roles) {
        if (item.id == _assignment!.roleId) {
          _role = item;
          break;
        }
      }

      if (_role == null) {
        _errorMessage =
            'The assigned role no longer exists. Contact an administrator.';
      }

      _isLoaded = true;
    } catch (error) {
      _assignment = null;
      _role = null;
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
    _assignment = null;
    _role = null;
    _errorMessage = null;
    notifyListeners();
  }
}
