import 'package:flutter/foundation.dart';

import '../../../../features/access_control/domain/entities/app_role_entity.dart';
import '../../../../features/access_control/domain/entities/user_role_assignment_entity.dart';
import '../../../../features/access_control/domain/services/access_control_service.dart';
import '../../domain/entities/audit_configuration_entity.dart';
import '../../domain/entities/audit_context.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../../domain/repositories/audit_configuration_repository.dart';
import '../../domain/repositories/audit_repository.dart';
import '../../domain/services/audit_service.dart';

class AuditServiceImpl implements AuditService {
  AuditServiceImpl(
    this._repository,
    this._accessControlService, [
    this._configurationRepository,
  ]) : _sessionId = _generateSessionId() {
    _configuration = AuditConfigurationEntity.defaultConfiguration();
    _startConfigurationListener();
  }

  final AuditRepository _repository;
  final AccessControlService _accessControlService;
  final AuditConfigurationRepository? _configurationRepository;
  final String _sessionId;

  late AuditConfigurationEntity _configuration;

  @override
  String get sessionId => _sessionId;

  void _startConfigurationListener() {
    final repository = _configurationRepository;

    if (repository == null) {
      return;
    }

    repository.watchConfiguration().listen(
      (configuration) {
        _configuration = configuration;
      },
      onError: (Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          debugPrint('Audit configuration listener error: $error');
        }
      },
    );
  }

  @override
  AuditContext buildContext({String? roleId, String? roleName}) {
    final assignment = _resolveAssignment(roleId: roleId, roleName: roleName);

    final role = _resolveRole(
      roleId: roleId ?? assignment?.roleId,
      roleName: roleName ?? assignment?.roleName,
    );

    return AuditContext(
      userId: _accessControlService.currentUserId ?? '',
      userName: assignment?.userName.trim().isNotEmpty == true
          ? assignment!.userName
          : _accessControlService.currentUserEmail ?? 'Unknown User',
      userEmail:
          _accessControlService.currentUserEmail ?? assignment?.email ?? '',
      roleId: role?.id ?? assignment?.roleId ?? roleId ?? '',
      roleName:
          role?.name ?? assignment?.roleName ?? roleName ?? 'Unknown Role',
      branchId: assignment?.branchId.trim().isNotEmpty == true
          ? assignment!.branchId
          : 'main',
      sessionId: _sessionId,
      platform: _platformName(),
      deviceName: '',
      ipAddress: '',
    );
  }

  @override
  Future<void> log({
    required String module,
    required AuditAction action,
    required String recordId,
    String description = '',
    Map<String, dynamic> oldValues = const {},
    Map<String, dynamic> newValues = const {},
    String? roleId,
    String? roleName,
  }) async {
    if (!_shouldRecordLog(module: module, action: action)) {
      return;
    }

    final context = buildContext(roleId: roleId, roleName: roleName);

    await _repository.saveLog(
      AuditLogEntity(
        id: _repository.generateId(),
        module: module.trim(),
        action: action,
        recordId: recordId.trim(),
        description: description.trim(),
        userId: context.userId,
        userName: context.userName,
        userEmail: context.userEmail,
        roleId: context.roleId,
        roleName: context.roleName,
        branchId: context.branchId,
        oldValues: Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(oldValues),
        ),
        newValues: Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(newValues),
        ),
        sessionId: context.sessionId,
        deviceName: context.deviceName,
        platform: context.platform,
        ipAddress: context.ipAddress,
        createdAt: DateTime.now(),
      ),
    );
  }

  bool _shouldRecordLog({required String module, required AuditAction action}) {
    if (!_configuration.isLoggingEnabled) {
      return false;
    }

    return _configuration.allowsLevel(
      _requiredLevel(module: module, action: action),
    );
  }

  AuditLogLevel _requiredLevel({
    required String module,
    required AuditAction action,
  }) {
    if (_isDetailedAction(action)) {
      return AuditLogLevel.detailed;
    }

    if (_isCriticalAction(action) || _isCriticalModule(module)) {
      return AuditLogLevel.critical;
    }

    return AuditLogLevel.standard;
  }

  bool _isDetailedAction(AuditAction action) {
    return switch (action) {
      AuditAction.view || AuditAction.print || AuditAction.export => true,
      _ => false,
    };
  }

  bool _isCriticalAction(AuditAction action) {
    return switch (action) {
      AuditAction.delete ||
      AuditAction.restore ||
      AuditAction.approve ||
      AuditAction.reject ||
      AuditAction.login ||
      AuditAction.logout ||
      AuditAction.collectPayment => true,
      _ => false,
    };
  }

  bool _isCriticalModule(String module) {
    final value = _normalizeValue(module);

    const keywords = <String>[
      'authentication',
      'accesscontrol',
      'permission',
      'role',
      'fee',
      'payment',
      'account',
      'cashbook',
      'income',
      'expense',
      'profitloss',
      'payroll',
      'salary',
      'teacherfinance',
      'employeefinance',
      'loan',
      'advance',
      'deduction',
      'penalty',
      'bonus',
      'allowance',
      'store',
      'settings',
      'audit',
      'backup',
    ];

    return keywords.any(value.contains);
  }

  static String _normalizeValue(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  @override
  Future<void> logCreate({
    required String module,
    required String recordId,
    String description = '',
    Map<String, dynamic> newValues = const {},
    String? roleId,
    String? roleName,
  }) {
    return log(
      module: module,
      action: AuditAction.create,
      recordId: recordId,
      description: description,
      newValues: newValues,
      roleId: roleId,
      roleName: roleName,
    );
  }

  @override
  Future<void> logUpdate({
    required String module,
    required String recordId,
    String description = '',
    Map<String, dynamic> oldValues = const {},
    Map<String, dynamic> newValues = const {},
    String? roleId,
    String? roleName,
  }) {
    return log(
      module: module,
      action: AuditAction.update,
      recordId: recordId,
      description: description,
      oldValues: oldValues,
      newValues: newValues,
      roleId: roleId,
      roleName: roleName,
    );
  }

  @override
  Future<void> logDelete({
    required String module,
    required String recordId,
    String description = '',
    Map<String, dynamic> oldValues = const {},
    String? roleId,
    String? roleName,
  }) {
    return log(
      module: module,
      action: AuditAction.delete,
      recordId: recordId,
      description: description,
      oldValues: oldValues,
      roleId: roleId,
      roleName: roleName,
    );
  }

  @override
  Future<void> logRestore({
    required String module,
    required String recordId,
    String description = '',
    Map<String, dynamic> newValues = const {},
    String? roleId,
    String? roleName,
  }) {
    return log(
      module: module,
      action: AuditAction.restore,
      recordId: recordId,
      description: description,
      newValues: newValues,
      roleId: roleId,
      roleName: roleName,
    );
  }

  UserRoleAssignmentEntity? _resolveAssignment({
    String? roleId,
    String? roleName,
  }) {
    final assignments = _accessControlService.assignments;

    if (roleId != null && roleId.trim().isNotEmpty) {
      for (final item in assignments) {
        if (item.roleId == roleId) {
          return item;
        }
      }
    }

    if (roleName != null && roleName.trim().isNotEmpty) {
      final value = roleName.trim().toLowerCase();

      for (final item in assignments) {
        if (item.roleName.trim().toLowerCase() == value) {
          return item;
        }
      }
    }

    return _accessControlService.assignment;
  }

  AppRoleEntity? _resolveRole({String? roleId, String? roleName}) {
    final roles = _accessControlService.roles;

    if (roleId != null && roleId.trim().isNotEmpty) {
      for (final item in roles) {
        if (item.id == roleId) {
          return item;
        }
      }
    }

    if (roleName != null && roleName.trim().isNotEmpty) {
      final value = roleName.trim().toLowerCase();

      for (final item in roles) {
        if (item.name.trim().toLowerCase() == value) {
          return item;
        }
      }
    }

    return _accessControlService.role;
  }

  static String _generateSessionId() {
    return 'session_${DateTime.now().microsecondsSinceEpoch}';
  }

  static String _platformName() {
    if (kIsWeb) {
      return 'web';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.windows => 'windows',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
