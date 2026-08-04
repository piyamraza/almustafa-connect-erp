[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\audit_phase2_$stamp"

function Full([string]$Path) { Join-Path $root $Path }

function ReadText([string]$Path) {
  [IO.File]::ReadAllText((Full $Path))
}

function WriteText([string]$Path, [string]$Text) {
  $full = Full $Path
  $dir = Split-Path $full -Parent

  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }

  [IO.File]::WriteAllText(
    $full,
    $Text.Replace("`r`n", "`n"),
    $utf8
  )
}

function BackupFile([string]$Path) {
  $source = Full $Path
  if (-not (Test-Path $source)) { return }

  $target = Join-Path $backup $Path
  $dir = Split-Path $target -Parent

  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }

  Copy-Item $source $target -Force
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run this script from the Flutter project root.'
}

$serviceLocator = 'lib/core/di/service_locator.dart'
$auditEntity = 'lib/core/audit/domain/entities/audit_log_entity.dart'
$auditRepository = 'lib/core/audit/domain/repositories/audit_repository.dart'
$accessService = 'lib/features/access_control/domain/services/access_control_service.dart'

foreach ($path in @(
  $serviceLocator,
  $auditEntity,
  $auditRepository,
  $accessService
)) {
  if (-not (Test-Path (Full $path))) {
    throw "REQUIRED FILE ERROR: $path"
  }
}

$auditContext =
  'lib/core/audit/domain/entities/audit_context.dart'
$auditService =
  'lib/core/audit/domain/services/audit_service.dart'
$auditServiceImpl =
  'lib/core/audit/data/services/audit_service_impl.dart'

New-Item -ItemType Directory -Path $backup -Force | Out-Null

foreach ($path in @(
  $serviceLocator,
  $auditContext,
  $auditService,
  $auditServiceImpl
)) {
  BackupFile $path
}

WriteText $auditContext @'
import 'package:equatable/equatable.dart';

class AuditContext extends Equatable {
  const AuditContext({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.roleId,
    required this.roleName,
    required this.branchId,
    required this.sessionId,
    required this.platform,
    this.deviceName = '',
    this.ipAddress = '',
  });

  final String userId;
  final String userName;
  final String userEmail;

  final String roleId;
  final String roleName;

  final String branchId;
  final String sessionId;

  final String platform;
  final String deviceName;
  final String ipAddress;

  @override
  List<Object?> get props => [
        userId,
        userName,
        userEmail,
        roleId,
        roleName,
        branchId,
        sessionId,
        platform,
        deviceName,
        ipAddress,
      ];
}
'@

WriteText $auditService @'
import '../entities/audit_context.dart';
import '../entities/audit_log_entity.dart';

abstract class AuditService {
  String get sessionId;

  AuditContext buildContext({
    String? roleId,
    String? roleName,
  });

  Future<void> log({
    required String module,
    required AuditAction action,
    required String recordId,
    String description = '',
    Map<String, dynamic> oldValues = const {},
    Map<String, dynamic> newValues = const {},
    String? roleId,
    String? roleName,
  });

  Future<void> logCreate({
    required String module,
    required String recordId,
    String description = '',
    Map<String, dynamic> newValues = const {},
    String? roleId,
    String? roleName,
  });

  Future<void> logUpdate({
    required String module,
    required String recordId,
    String description = '',
    Map<String, dynamic> oldValues = const {},
    Map<String, dynamic> newValues = const {},
    String? roleId,
    String? roleName,
  });

  Future<void> logDelete({
    required String module,
    required String recordId,
    String description = '',
    Map<String, dynamic> oldValues = const {},
    String? roleId,
    String? roleName,
  });

  Future<void> logRestore({
    required String module,
    required String recordId,
    String description = '',
    Map<String, dynamic> newValues = const {},
    String? roleId,
    String? roleName,
  });
}
'@

WriteText $auditServiceImpl @'
import 'package:flutter/foundation.dart';

import '../../../features/access_control/domain/entities/app_role_entity.dart';
import '../../../features/access_control/domain/entities/user_role_assignment_entity.dart';
import '../../../features/access_control/domain/services/access_control_service.dart';
import '../../domain/entities/audit_context.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../../domain/repositories/audit_repository.dart';
import '../../domain/services/audit_service.dart';

class AuditServiceImpl implements AuditService {
  AuditServiceImpl(
    this._repository,
    this._accessControlService,
  ) : _sessionId = _generateSessionId();

  final AuditRepository _repository;
  final AccessControlService _accessControlService;
  final String _sessionId;

  @override
  String get sessionId => _sessionId;

  @override
  AuditContext buildContext({
    String? roleId,
    String? roleName,
  }) {
    final assignment = _resolveAssignment(
      roleId: roleId,
      roleName: roleName,
    );

    final role = _resolveRole(
      roleId: roleId ?? assignment?.roleId,
      roleName: roleName ?? assignment?.roleName,
    );

    return AuditContext(
      userId: _accessControlService.currentUserId ?? '',
      userName: assignment?.userName.trim().isNotEmpty == true
          ? assignment!.userName
          : _accessControlService.currentUserEmail ?? 'Unknown User',
      userEmail: _accessControlService.currentUserEmail ??
          assignment?.email ??
          '',
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
    final context = buildContext(
      roleId: roleId,
      roleName: roleName,
    );

    final now = DateTime.now();
    final id = _repository.generateId();

    await _repository.saveLog(
      AuditLogEntity(
        id: id,
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
        createdAt: now,
      ),
    );
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
        if (item.roleId == roleId) return item;
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

  AppRoleEntity? _resolveRole({
    String? roleId,
    String? roleName,
  }) {
    final roles = _accessControlService.roles;

    if (roleId != null && roleId.trim().isNotEmpty) {
      for (final item in roles) {
        if (item.id == roleId) return item;
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
    final now = DateTime.now();

    return 'session_${now.microsecondsSinceEpoch}';
  }

  static String _platformName() {
    if (kIsWeb) return 'web';

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
'@

$locatorText = ReadText $serviceLocator
$normalized = $locatorText.Replace("`r`n", "`n")

$imports = @"
import '../audit/data/datasources/audit_remote_datasource.dart';
import '../audit/data/repositories/audit_repository_impl.dart';
import '../audit/data/services/audit_service_impl.dart';
import '../audit/domain/repositories/audit_repository.dart';
import '../audit/domain/services/audit_service.dart';
"@

if (-not $normalized.Contains(
  "import '../audit/domain/services/audit_service.dart';"
)) {
  $firstImportIndex = $normalized.IndexOf('import ')

  if ($firstImportIndex -lt 0) {
    throw 'SERVICE LOCATOR IMPORT ANCHOR ERROR.'
  }

  $normalized =
    $normalized.Substring(0, $firstImportIndex) +
    $imports +
    "`n" +
    $normalized.Substring($firstImportIndex)
}

$registrationMarker =
  "sl.registerLazySingleton<AuditService>("

if (-not $normalized.Contains($registrationMarker)) {
  $setupMatch = [regex]::Match(
    $normalized,
    'Future<void>\s+setupServiceLocator\s*\(\s*\)\s*async\s*\{'
  )

  if (-not $setupMatch.Success) {
    throw 'SERVICE LOCATOR SETUP FUNCTION ANCHOR ERROR.'
  }

  $insertIndex = $setupMatch.Index + $setupMatch.Length

  $registrations = @"

  sl.registerLazySingleton<AuditRemoteDataSource>(
    () => AuditRemoteDataSource(),
  );

  sl.registerLazySingleton<AuditRepository>(
    () => AuditRepositoryImpl(
      sl<AuditRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<AuditService>(
    () => AuditServiceImpl(
      sl<AuditRepository>(),
      sl<AccessControlService>(),
    ),
  );

"@

  $normalized =
    $normalized.Substring(0, $insertIndex) +
    $registrations +
    $normalized.Substring($insertIndex)
}

WriteText $serviceLocator $normalized

& dart format `
  lib/core/audit `
  $serviceLocator

if ($LASTEXITCODE -ne 0) {
  throw "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze `
  lib/core/audit `
  $serviceLocator `
  --no-fatal-infos `
  --no-fatal-warnings

if ($LASTEXITCODE -ne 0) {
  throw "AUDIT PHASE 2 ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Audit Phase 2 installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Added AuditContext, AuditService, role-used resolution, session tracking, and service locator registrations.' -ForegroundColor Yellow
