import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/app_permission.dart';
import '../../domain/services/access_control_service.dart';
import '../pages/unauthorized_access_page.dart';

class PermissionGuard extends StatefulWidget {
  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.moduleName,
    this.loading,
    this.unauthorized,
  });

  final AppPermission permission;
  final Widget child;
  final String? moduleName;
  final Widget? loading;
  final Widget? unauthorized;

  @override
  State<PermissionGuard> createState() => _PermissionGuardState();
}

class _PermissionGuardState extends State<PermissionGuard> {
  late final AccessControlService _access;

  @override
  void initState() {
    super.initState();
    _access = sl<AccessControlService>();
    _access.addListener(_refresh);
    _access.loadCurrentAccess();
  }

  @override
  void dispose() {
    _access.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_access.isLoaded || _access.isLoading) {
      return widget.loading ??
          const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_access.hasPermission(widget.permission)) {
      return widget.child;
    }

    return widget.unauthorized ??
        UnauthorizedAccessPage(moduleName: widget.moduleName);
  }
}

class PermissionVisibility extends StatefulWidget {
  const PermissionVisibility({
    super.key,
    required this.permission,
    required this.child,
    this.replacement = const SizedBox.shrink(),
  });

  final AppPermission permission;
  final Widget child;
  final Widget replacement;

  @override
  State<PermissionVisibility> createState() => _PermissionVisibilityState();
}

class _PermissionVisibilityState extends State<PermissionVisibility> {
  late final AccessControlService _access;

  @override
  void initState() {
    super.initState();
    _access = sl<AccessControlService>();
    _access.addListener(_refresh);
    _access.loadCurrentAccess();
  }

  @override
  void dispose() {
    _access.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _access.hasPermission(widget.permission)
        ? widget.child
        : widget.replacement;
  }
}
