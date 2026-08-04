[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\audit_phase1_$stamp"

function Full([string]$Path) { Join-Path $root $Path }
function WriteUtf8([string]$Path, [string]$Text) {
  $full = Full $Path
  $dir = Split-Path $full -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  [IO.File]::WriteAllText($full, $Text.Replace("`r`n", "`n"), $utf8)
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

$firestorePaths = 'lib/core/constants/firestore_paths.dart'
if (-not (Test-Path (Full $firestorePaths))) {
  throw "REQUIRED FILE ERROR: $firestorePaths"
}

$entity = 'lib/core/audit/domain/entities/audit_log_entity.dart'
$model = 'lib/core/audit/data/models/audit_log_model.dart'
$datasource = 'lib/core/audit/data/datasources/audit_remote_datasource.dart'
$repository = 'lib/core/audit/domain/repositories/audit_repository.dart'
$repositoryImpl = 'lib/core/audit/data/repositories/audit_repository_impl.dart'

New-Item -ItemType Directory -Path $backup -Force | Out-Null
BackupFile $firestorePaths
foreach ($file in @($entity, $model, $datasource, $repository, $repositoryImpl)) {
  BackupFile $file
}

WriteUtf8 $entity @'
import 'package:equatable/equatable.dart';

enum AuditAction {
  create,
  update,
  delete,
  restore,
  approve,
  reject,
  login,
  logout,
  view,
  print,
  export,
  send,
  collectPayment,
  other,
}

class AuditLogEntity extends Equatable {
  const AuditLogEntity({
    required this.id,
    required this.module,
    required this.action,
    required this.recordId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.roleId,
    required this.roleName,
    required this.branchId,
    required this.createdAt,
    this.description = '',
    this.oldValues = const {},
    this.newValues = const {},
    this.sessionId = '',
    this.deviceName = '',
    this.platform = '',
    this.ipAddress = '',
  });

  final String id;
  final String module;
  final AuditAction action;
  final String recordId;
  final String description;
  final String userId;
  final String userName;
  final String userEmail;
  final String roleId;
  final String roleName;
  final String branchId;
  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;
  final String sessionId;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        module,
        action,
        recordId,
        description,
        userId,
        userName,
        userEmail,
        roleId,
        roleName,
        branchId,
        oldValues,
        newValues,
        sessionId,
        deviceName,
        platform,
        ipAddress,
        createdAt,
      ];
}
'@

WriteUtf8 $model @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/audit_log_entity.dart';

class AuditLogModel extends AuditLogEntity {
  const AuditLogModel({
    required super.id,
    required super.module,
    required super.action,
    required super.recordId,
    required super.userId,
    required super.userName,
    required super.userEmail,
    required super.roleId,
    required super.roleName,
    required super.branchId,
    required super.createdAt,
    super.description,
    super.oldValues,
    super.newValues,
    super.sessionId,
    super.deviceName,
    super.platform,
    super.ipAddress,
  });

  factory AuditLogModel.fromEntity(AuditLogEntity value) {
    return AuditLogModel(
      id: value.id,
      module: value.module,
      action: value.action,
      recordId: value.recordId,
      description: value.description,
      userId: value.userId,
      userName: value.userName,
      userEmail: value.userEmail,
      roleId: value.roleId,
      roleName: value.roleName,
      branchId: value.branchId,
      oldValues: value.oldValues,
      newValues: value.newValues,
      sessionId: value.sessionId,
      deviceName: value.deviceName,
      platform: value.platform,
      ipAddress: value.ipAddress,
      createdAt: value.createdAt,
    );
  }

  factory AuditLogModel.fromMap(String id, Map<String, dynamic> map) {
    return AuditLogModel(
      id: id,
      module: map['module'] as String? ?? '',
      action: AuditAction.values.firstWhere(
        (item) => item.name == map['action'],
        orElse: () => AuditAction.other,
      ),
      recordId: map['recordId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      roleId: map['roleId'] as String? ?? '',
      roleName: map['roleName'] as String? ?? '',
      branchId: map['branchId'] as String? ?? 'main',
      oldValues: Map<String, dynamic>.from(
        map['oldValues'] as Map? ?? const {},
      ),
      newValues: Map<String, dynamic>.from(
        map['newValues'] as Map? ?? const {},
      ),
      sessionId: map['sessionId'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? '',
      platform: map['platform'] as String? ?? '',
      ipAddress: map['ipAddress'] as String? ?? '',
      createdAt: _date(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'module': module,
        'action': action.name,
        'recordId': recordId,
        'description': description,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'roleId': roleId,
        'roleName': roleName,
        'branchId': branchId,
        'oldValues': oldValues,
        'newValues': newValues,
        'sessionId': sessionId,
        'deviceName': deviceName,
        'platform': platform,
        'ipAddress': ipAddress,
        'createdAt': Timestamp.fromDate(createdAt),
        'schemaVersion': 1,
      };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
'@

WriteUtf8 $datasource @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../constants/firestore_paths.dart';
import '../models/audit_log_model.dart';

class AuditRemoteDataSource {
  AuditRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.auditLogs);

  String generateId() => _collection.doc().id;

  Future<void> save(AuditLogModel log) {
    return _collection.doc(log.id).set(log.toMap());
  }

  Future<List<AuditLogModel>> getLogs({
    String? module,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 200,
  }) async {
    final snapshot = await _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    final values = snapshot.docs
        .map((doc) => AuditLogModel.fromMap(doc.id, doc.data()))
        .where((item) {
          if (module != null && item.module != module) return false;
          if (userId != null && item.userId != userId) return false;
          if (fromDate != null && item.createdAt.isBefore(fromDate)) {
            return false;
          }
          if (toDate != null && item.createdAt.isAfter(toDate)) {
            return false;
          }
          return true;
        })
        .toList();

    return List.unmodifiable(values);
  }
}
'@

WriteUtf8 $repository @'
import '../entities/audit_log_entity.dart';

abstract class AuditRepository {
  String generateId();

  Future<void> saveLog(AuditLogEntity log);

  Future<List<AuditLogEntity>> getLogs({
    String? module,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 200,
  });
}
'@

WriteUtf8 $repositoryImpl @'
import '../../domain/entities/audit_log_entity.dart';
import '../../domain/repositories/audit_repository.dart';
import '../datasources/audit_remote_datasource.dart';
import '../models/audit_log_model.dart';

class AuditRepositoryImpl implements AuditRepository {
  const AuditRepositoryImpl(this._remoteDataSource);

  final AuditRemoteDataSource _remoteDataSource;

  @override
  String generateId() => _remoteDataSource.generateId();

  @override
  Future<void> saveLog(AuditLogEntity log) {
    return _remoteDataSource.save(
      AuditLogModel.fromEntity(log),
    );
  }

  @override
  Future<List<AuditLogEntity>> getLogs({
    String? module,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 200,
  }) {
    return _remoteDataSource.getLogs(
      module: module,
      userId: userId,
      fromDate: fromDate,
      toDate: toDate,
      limit: limit,
    );
  }
}
'@

$pathsText = [IO.File]::ReadAllText((Full $firestorePaths))
if (-not $pathsText.Contains("static const String auditLogs = 'audit_logs';")) {
  $anchor = "class FirestorePaths {`n  FirestorePaths._();"
  if (-not $pathsText.Replace("`r`n", "`n").Contains($anchor)) {
    throw 'FIRESTORE PATHS ANCHOR ERROR.'
  }
  $normalized = $pathsText.Replace("`r`n", "`n")
  $normalized = $normalized.Replace(
    $anchor,
    "$anchor`n`n  static const String auditLogs = 'audit_logs';"
  )
  [IO.File]::WriteAllText((Full $firestorePaths), $normalized, $utf8)
}

& dart format lib/core/audit $firestorePaths
if ($LASTEXITCODE -ne 0) {
  throw "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze lib/core/audit $firestorePaths --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) {
  throw "AUDIT PHASE 1 ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Audit Phase 1 installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Created audit entity, model, datasource, repository and Firestore path.' -ForegroundColor Yellow
Write-Host 'Firestore collection: audit_logs' -ForegroundColor Yellow
