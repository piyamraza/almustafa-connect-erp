[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\settings_phase4_$stamp"

function FullPath([string]$Path) { Join-Path $root $Path }
function ReadUtf8([string]$Path) { [IO.File]::ReadAllText((FullPath $Path)) }

function WriteUtf8([string]$Path,[string]$Text) {
  $full = FullPath $Path
  $dir = Split-Path $full -Parent

  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }

  [IO.File]::WriteAllText(
    $full,
    $Text.Replace("`r`n","`n"),
    $utf8
  )
}

function BackupFile([string]$Path) {
  $source = FullPath $Path
  if (-not (Test-Path $source)) { return }

  $target = Join-Path $backup $Path
  $dir = Split-Path $target -Parent

  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }

  Copy-Item $source $target -Force
}

function InsertBefore(
  [string]$Path,
  [string]$Anchor,
  [string]$InsertText
) {
  $text = ReadUtf8 $Path

  if ($text.Contains($InsertText.Trim())) {
    return
  }

  $index = $text.IndexOf(
    $Anchor,
    [StringComparison]::Ordinal
  )

  if ($index -lt 0) {
    throw "ANCHOR ERROR in $Path : $Anchor"
  }

  BackupFile $Path

  WriteUtf8 $Path (
    $text.Substring(0,$index) +
    $InsertText +
    $text.Substring($index)
  )
}

if (-not (Test-Path (FullPath 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run from Flutter project root.'
}

$required = @(
  'lib/features/settings/presentation/pages/settings_dashboard_page.dart',
  'lib/core/constants/firestore_paths.dart',
  'lib/core/di/service_locator.dart',
  'lib/core/services/firebase_firestore_service.dart'
)

foreach ($path in $required) {
  if (-not (Test-Path (FullPath $path))) {
    throw "REQUIRED FILE ERROR: $path"
  }
}

if (Test-Path (FullPath 'lib/features/settings/domain/entities/security_session_entity.dart')) {
  throw 'EXISTING FILE ERROR: Settings Phase 4 appears already installed.'
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($path in $required) { BackupFile $path }

WriteUtf8 'lib/features/settings/domain/entities/security_session_entity.dart' @'
import 'package:equatable/equatable.dart';

class SecuritySessionEntity extends Equatable {
  const SecuritySessionEntity({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.platform,
    required this.lastActiveAt,
    required this.createdAt,
    required this.isCurrent,
    required this.isRevoked,
    this.ipAddress = '',
    this.appVersion = '',
  });

  final String id;
  final String userId;
  final String deviceName;
  final String platform;
  final DateTime lastActiveAt;
  final DateTime createdAt;
  final bool isCurrent;
  final bool isRevoked;
  final String ipAddress;
  final String appVersion;

  @override
  List<Object?> get props => [
        id,
        userId,
        deviceName,
        platform,
        lastActiveAt,
        createdAt,
        isCurrent,
        isRevoked,
        ipAddress,
        appVersion,
      ];
}
'@

WriteUtf8 'lib/features/settings/domain/entities/login_history_entity.dart' @'
import 'package:equatable/equatable.dart';

enum LoginActivityType {
  login,
  logout,
  failedLogin,
  passwordChanged,
  sessionRevoked,
}

class LoginHistoryEntity extends Equatable {
  const LoginHistoryEntity({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.occurredAt,
    required this.success,
    this.deviceName = '',
    this.platform = '',
    this.ipAddress = '',
    this.details = '',
  });

  final String id;
  final String userId;
  final LoginActivityType activityType;
  final DateTime occurredAt;
  final bool success;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final String details;

  @override
  List<Object?> get props => [
        id,
        userId,
        activityType,
        occurredAt,
        success,
        deviceName,
        platform,
        ipAddress,
        details,
      ];
}
'@

WriteUtf8 'lib/features/settings/data/models/security_models.dart' @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/login_history_entity.dart';
import '../../domain/entities/security_session_entity.dart';

DateTime _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse('$value') ?? DateTime.now();
}

class SecuritySessionModel extends SecuritySessionEntity {
  const SecuritySessionModel({
    required super.id,
    required super.userId,
    required super.deviceName,
    required super.platform,
    required super.lastActiveAt,
    required super.createdAt,
    required super.isCurrent,
    required super.isRevoked,
    super.ipAddress,
    super.appVersion,
  });

  factory SecuritySessionModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return SecuritySessionModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? '',
      platform: map['platform'] as String? ?? '',
      lastActiveAt: _date(map['lastActiveAt']),
      createdAt: _date(map['createdAt']),
      isCurrent: map['isCurrent'] as bool? ?? false,
      isRevoked: map['isRevoked'] as bool? ?? false,
      ipAddress: map['ipAddress'] as String? ?? '',
      appVersion: map['appVersion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'deviceName': deviceName,
        'platform': platform,
        'lastActiveAt': lastActiveAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'isCurrent': isCurrent,
        'isRevoked': isRevoked,
        'ipAddress': ipAddress,
        'appVersion': appVersion,
        'schemaVersion': 1,
      };
}

class LoginHistoryModel extends LoginHistoryEntity {
  const LoginHistoryModel({
    required super.id,
    required super.userId,
    required super.activityType,
    required super.occurredAt,
    required super.success,
    super.deviceName,
    super.platform,
    super.ipAddress,
    super.details,
  });

  factory LoginHistoryModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return LoginHistoryModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      activityType: LoginActivityType.values.firstWhere(
        (item) => item.name == map['activityType'],
        orElse: () => LoginActivityType.login,
      ),
      occurredAt: _date(map['occurredAt']),
      success: map['success'] as bool? ?? true,
      deviceName: map['deviceName'] as String? ?? '',
      platform: map['platform'] as String? ?? '',
      ipAddress: map['ipAddress'] as String? ?? '',
      details: map['details'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'activityType': activityType.name,
        'occurredAt': occurredAt.toIso8601String(),
        'success': success,
        'deviceName': deviceName,
        'platform': platform,
        'ipAddress': ipAddress,
        'details': details,
        'schemaVersion': 1,
      };
}
'@

WriteUtf8 'lib/features/settings/domain/repositories/security_repository.dart' @'
import '../entities/login_history_entity.dart';
import '../entities/security_session_entity.dart';

abstract class SecurityRepository {
  Future<List<SecuritySessionEntity>> getSessions(
    String userId,
  );

  Future<List<LoginHistoryEntity>> getLoginHistory(
    String userId,
  );

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> revokeSession({
    required String sessionId,
    required String userId,
  });
}
'@

WriteUtf8 'lib/features/settings/data/datasources/security_remote_datasource.dart' @'
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/login_history_entity.dart';
import '../../domain/entities/security_session_entity.dart';
import '../models/security_models.dart';

abstract class SecurityRemoteDataSource {
  Future<List<SecuritySessionEntity>> getSessions(
    String userId,
  );

  Future<List<LoginHistoryEntity>> getLoginHistory(
    String userId,
  );

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> revokeSession({
    required String sessionId,
    required String userId,
  });
}

class SecurityRemoteDataSourceImpl
    implements SecurityRemoteDataSource {
  const SecurityRemoteDataSourceImpl(
    this._firestore,
    this._auth,
  );

  final FirebaseFirestoreService _firestore;
  final FirebaseAuth _auth;

  @override
  Future<List<SecuritySessionEntity>> getSessions(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.activeSessions)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => SecuritySessionModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .where((item) => item.userId == userId)
        .toList();

    values.sort(
      (a, b) =>
          b.lastActiveAt.compareTo(a.lastActiveAt),
    );

    return values;
  }

  @override
  Future<List<LoginHistoryEntity>> getLoginHistory(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.loginHistory)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => LoginHistoryModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .where((item) => item.userId == userId)
        .toList();

    values.sort(
      (a, b) =>
          b.occurredAt.compareTo(a.occurredAt),
    );

    return values;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw StateError('No signed-in user found.');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);

    final now = DateTime.now();

    await _firestore
        .collection(FirestorePaths.securityLogs)
        .doc('password_${now.microsecondsSinceEpoch}')
        .set(
          LoginHistoryModel(
            id: 'password_${now.microsecondsSinceEpoch}',
            userId: user.uid,
            activityType:
                LoginActivityType.passwordChanged,
            occurredAt: now,
            success: true,
            details: 'Password changed by user.',
          ).toMap(),
        );
  }

  @override
  Future<void> revokeSession({
    required String sessionId,
    required String userId,
  }) async {
    final document = await _firestore
        .collection(FirestorePaths.activeSessions)
        .doc(sessionId)
        .get();

    if (!document.exists) {
      throw StateError('Session was not found.');
    }

    final session = SecuritySessionModel.fromMap({
      ...document.data()!,
      'id': document.id,
    });

    final updated = SecuritySessionModel(
      id: session.id,
      userId: session.userId,
      deviceName: session.deviceName,
      platform: session.platform,
      lastActiveAt: DateTime.now(),
      createdAt: session.createdAt,
      isCurrent: session.isCurrent,
      isRevoked: true,
      ipAddress: session.ipAddress,
      appVersion: session.appVersion,
    );

    await _firestore
        .collection(FirestorePaths.activeSessions)
        .doc(sessionId)
        .set(updated.toMap());

    final now = DateTime.now();

    await _firestore
        .collection(FirestorePaths.securityLogs)
        .doc('revoke_${now.microsecondsSinceEpoch}')
        .set(
          LoginHistoryModel(
            id: 'revoke_${now.microsecondsSinceEpoch}',
            userId: userId,
            activityType:
                LoginActivityType.sessionRevoked,
            occurredAt: now,
            success: true,
            details: 'Session $sessionId revoked.',
          ).toMap(),
        );
  }
}
'@

WriteUtf8 'lib/features/settings/data/repositories/security_repository_impl.dart' @'
import '../../domain/entities/login_history_entity.dart';
import '../../domain/entities/security_session_entity.dart';
import '../../domain/repositories/security_repository.dart';
import '../datasources/security_remote_datasource.dart';

class SecurityRepositoryImpl
    implements SecurityRepository {
  const SecurityRepositoryImpl(this._source);

  final SecurityRemoteDataSource _source;

  @override
  Future<List<SecuritySessionEntity>> getSessions(
    String userId,
  ) {
    return _source.getSessions(userId);
  }

  @override
  Future<List<LoginHistoryEntity>> getLoginHistory(
    String userId,
  ) {
    return _source.getLoginHistory(userId);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _source.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> revokeSession({
    required String sessionId,
    required String userId,
  }) {
    return _source.revokeSession(
      sessionId: sessionId,
      userId: userId,
    );
  }
}
'@

WriteUtf8 'lib/features/settings/domain/usecases/manage_security.dart' @'
import '../entities/login_history_entity.dart';
import '../entities/security_session_entity.dart';
import '../repositories/security_repository.dart';

class SecurityData {
  const SecurityData({
    required this.sessions,
    required this.loginHistory,
  });

  final List<SecuritySessionEntity> sessions;
  final List<LoginHistoryEntity> loginHistory;
}

class GetSecurityData {
  const GetSecurityData(this._repository);

  final SecurityRepository _repository;

  Future<SecurityData> call(String userId) async {
    final values = await Future.wait<Object>([
      _repository.getSessions(userId),
      _repository.getLoginHistory(userId),
    ]);

    return SecurityData(
      sessions:
          values[0] as List<SecuritySessionEntity>,
      loginHistory:
          values[1] as List<LoginHistoryEntity>,
    );
  }
}

class ChangeUserPassword {
  const ChangeUserPassword(this._repository);

  final SecurityRepository _repository;

  Future<void> call({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    if (currentPassword.isEmpty) {
      throw ArgumentError(
        'Current password is required.',
      );
    }

    if (newPassword.length < 8) {
      throw ArgumentError(
        'New password must contain at least 8 characters.',
      );
    }

    if (newPassword != confirmPassword) {
      throw ArgumentError(
        'New password and confirmation do not match.',
      );
    }

    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

class RevokeUserSession {
  const RevokeUserSession(this._repository);

  final SecurityRepository _repository;

  Future<void> call({
    required String sessionId,
    required String userId,
  }) {
    if (sessionId.trim().isEmpty) {
      throw ArgumentError('Session ID is required.');
    }

    return _repository.revokeSession(
      sessionId: sessionId,
      userId: userId,
    );
  }
}
'@

WriteUtf8 'lib/features/settings/presentation/bloc/security_event.dart' @'
import 'package:equatable/equatable.dart';

sealed class SecurityEvent extends Equatable {
  const SecurityEvent();

  @override
  List<Object?> get props => const [];
}

class LoadSecurityData extends SecurityEvent {
  const LoadSecurityData(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class ChangePasswordRequested extends SecurityEvent {
  const ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  @override
  List<Object?> get props => [
        currentPassword,
        newPassword,
        confirmPassword,
      ];
}

class RevokeSessionRequested extends SecurityEvent {
  const RevokeSessionRequested({
    required this.sessionId,
    required this.userId,
  });

  final String sessionId;
  final String userId;

  @override
  List<Object?> get props => [sessionId, userId];
}
'@

WriteUtf8 'lib/features/settings/presentation/bloc/security_state.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/login_history_entity.dart';
import '../../domain/entities/security_session_entity.dart';

sealed class SecurityState extends Equatable {
  const SecurityState();

  @override
  List<Object?> get props => const [];
}

class SecurityInitial extends SecurityState {
  const SecurityInitial();
}

class SecurityLoading extends SecurityState {
  const SecurityLoading();
}

class SecurityLoaded extends SecurityState {
  const SecurityLoaded({
    required this.sessions,
    required this.loginHistory,
    required this.userId,
    this.processing = false,
    this.message,
  });

  final List<SecuritySessionEntity> sessions;
  final List<LoginHistoryEntity> loginHistory;
  final String userId;
  final bool processing;
  final String? message;

  @override
  List<Object?> get props => [
        sessions,
        loginHistory,
        userId,
        processing,
        message,
      ];
}

class SecurityFailure extends SecurityState {
  const SecurityFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
'@

WriteUtf8 'lib/features/settings/presentation/bloc/security_bloc.dart' @'
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_security.dart';
import 'security_event.dart';
import 'security_state.dart';

class SecurityBloc
    extends Bloc<SecurityEvent, SecurityState> {
  SecurityBloc({
    required GetSecurityData getData,
    required ChangeUserPassword changePassword,
    required RevokeUserSession revokeSession,
  })  : _getData = getData,
        _changePassword = changePassword,
        _revokeSession = revokeSession,
        super(const SecurityInitial()) {
    on<LoadSecurityData>(_load);
    on<ChangePasswordRequested>(_change);
    on<RevokeSessionRequested>(_revoke);
  }

  final GetSecurityData _getData;
  final ChangeUserPassword _changePassword;
  final RevokeUserSession _revokeSession;

  Future<void> _load(
    LoadSecurityData event,
    Emitter<SecurityState> emit,
  ) async {
    emit(const SecurityLoading());
    await _reload(emit, event.userId);
  }

  Future<void> _change(
    ChangePasswordRequested event,
    Emitter<SecurityState> emit,
  ) async {
    final current = state;

    if (current is! SecurityLoaded) {
      return;
    }

    try {
      await _changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );

      await _reload(
        emit,
        current.userId,
        message: 'Password changed successfully.',
      );
    } catch (error) {
      emit(SecurityFailure(_message(error)));
    }
  }

  Future<void> _revoke(
    RevokeSessionRequested event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      await _revokeSession(
        sessionId: event.sessionId,
        userId: event.userId,
      );

      await _reload(
        emit,
        event.userId,
        message: 'Session revoked successfully.',
      );
    } catch (error) {
      emit(SecurityFailure(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<SecurityState> emit,
    String userId, {
    String? message,
  }) async {
    try {
      final data = await _getData(userId);

      emit(
        SecurityLoaded(
          sessions: data.sessions,
          loginHistory: data.loginHistory,
          userId: userId,
          message: message,
        ),
      );
    } catch (error) {
      emit(SecurityFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
'@

WriteUtf8 'lib/features/settings/presentation/pages/security_sessions_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../bloc/security_bloc.dart';
import '../bloc/security_event.dart';
import '../bloc/security_state.dart';

class SecuritySessionsPage extends StatelessWidget {
  const SecuritySessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =
        sl<GetCurrentUserUseCase>()()?.uid ?? '';

    return BlocProvider(
      create: (_) => sl<SecurityBloc>()
        ..add(LoadSecurityData(userId)),
      child: const _SecuritySessionsView(),
    );
  }
}

class _SecuritySessionsView extends StatelessWidget {
  const _SecuritySessionsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security and Sessions'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<SecurityBloc, SecurityState>(
        listener: (context, state) {
          if (state is SecurityLoaded &&
              state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if (state is SecurityInitial ||
              state is SecurityLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is SecurityFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as SecurityLoaded;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () =>
                      _changePassword(context),
                  icon: const Icon(Icons.password_outlined),
                  label: const Text('Change Password'),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Active Sessions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (data.sessions.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('No session records found.'),
                  ),
                ),
              ...data.sessions.map(
                (session) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        session.isCurrent
                            ? Icons.devices
                            : Icons.devices_other,
                      ),
                    ),
                    title: Text(
                      session.deviceName.isEmpty
                          ? 'Unknown Device'
                          : session.deviceName,
                    ),
                    subtitle: Text(
                      '${session.platform} - '
                      '${_date(session.lastActiveAt)}',
                    ),
                    trailing: session.isCurrent ||
                            session.isRevoked
                        ? Text(
                            session.isCurrent
                                ? 'Current'
                                : 'Revoked',
                          )
                        : TextButton(
                            onPressed: () {
                              context.read<SecurityBloc>().add(
                                    RevokeSessionRequested(
                                      sessionId: session.id,
                                      userId: data.userId,
                                    ),
                                  );
                            },
                            child: const Text('Revoke'),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Login History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (data.loginHistory.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('No login history found.'),
                  ),
                ),
              ...data.loginHistory.take(50).map(
                    (entry) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            entry.success
                                ? Icons.verified_user_outlined
                                : Icons.warning_amber_outlined,
                          ),
                        ),
                        title: Text(entry.activityType.name),
                        subtitle: Text(
                          '${entry.deviceName} - '
                          '${_date(entry.occurredAt)}',
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _changePassword(
    BuildContext context,
  ) async {
    final currentController =
        TextEditingController();
    final newController = TextEditingController();
    final confirmController =
        TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (save == true && context.mounted) {
      context.read<SecurityBloc>().add(
            ChangePasswordRequested(
              currentPassword:
                  currentController.text,
              newPassword: newController.text,
              confirmPassword:
                  confirmController.text,
            ),
          );
    }

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  static String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}
'@

$pathsFile = 'lib/core/constants/firestore_paths.dart'
$pathsText = ReadUtf8 $pathsFile

if (-not $pathsText.Contains(
  'static const String activeSessions'
)) {
  $anchor = "  static const String userPreferences = 'user_preferences';"

  if (-not $pathsText.Contains($anchor)) {
    throw 'FIRESTORE PATH ANCHOR ERROR.'
  }

  $replacement = @"
$anchor
  static const String activeSessions = 'active_sessions';
  static const String loginHistory = 'login_history';
  static const String securityLogs = 'security_logs';
"@

  BackupFile $pathsFile
  WriteUtf8 $pathsFile (
    $pathsText.Replace($anchor,$replacement)
  )
}

$slFile = 'lib/core/di/service_locator.dart'
$slText = ReadUtf8 $slFile

$imports = @"
import '../../features/settings/data/datasources/security_remote_datasource.dart';
import '../../features/settings/data/repositories/security_repository_impl.dart';
import '../../features/settings/domain/repositories/security_repository.dart';
import '../../features/settings/domain/usecases/manage_security.dart';
import '../../features/settings/presentation/bloc/security_bloc.dart';
"@

if (-not $slText.Contains(
  'security_remote_datasource.dart'
)) {
  InsertBefore `
    $slFile `
    "import '../../features/settings/data/datasources/settings_remote_datasource.dart';" `
    $imports
}

$registrations = @"
  sl.registerLazySingleton<SecurityRemoteDataSource>(
    () => SecurityRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
      sl<FirebaseAuth>(),
    ),
  );
  sl.registerLazySingleton<SecurityRepository>(
    () => SecurityRepositoryImpl(
      sl<SecurityRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetSecurityData>(
    () => GetSecurityData(
      sl<SecurityRepository>(),
    ),
  );
  sl.registerLazySingleton<ChangeUserPassword>(
    () => ChangeUserPassword(
      sl<SecurityRepository>(),
    ),
  );
  sl.registerLazySingleton<RevokeUserSession>(
    () => RevokeUserSession(
      sl<SecurityRepository>(),
    ),
  );
  sl.registerFactory<SecurityBloc>(
    () => SecurityBloc(
      getData: sl<GetSecurityData>(),
      changePassword: sl<ChangeUserPassword>(),
      revokeSession: sl<RevokeUserSession>(),
    ),
  );

"@

if (-not $slText.Contains(
  'sl.registerLazySingleton<SecurityRepository>'
)) {
  InsertBefore `
    $slFile `
    '  sl.registerLazySingleton<SettingsRemoteDataSource>(' `
    $registrations
}

$settingsPage = 'lib/features/settings/presentation/pages/settings_dashboard_page.dart'
$settingsText = ReadUtf8 $settingsPage

if (-not $settingsText.Contains(
  "import 'security_sessions_page.dart';"
)) {
  $anchor = "import 'user_preferences_page.dart';"

  if (-not $settingsText.Contains($anchor)) {
    throw 'SETTINGS PAGE IMPORT ANCHOR ERROR.'
  }

  BackupFile $settingsPage
  WriteUtf8 $settingsPage (
    $settingsText.Replace(
      $anchor,
      "$anchor`nimport 'security_sessions_page.dart';"
    )
  )
}

$settingsText = ReadUtf8 $settingsPage

if (-not $settingsText.Contains(
  'const SecuritySessionsPage()'
)) {
  $anchor = "label: const Text('User Preferences'),"
  $index = $settingsText.IndexOf(
    $anchor,
    [StringComparison]::Ordinal
  )

  if ($index -lt 0) {
    throw 'SETTINGS SECURITY BUTTON ANCHOR ERROR.'
  }

  $buttonEnd = $settingsText.IndexOf(
    "`n                ),",
    $index,
    [StringComparison]::Ordinal
  )

  if ($buttonEnd -lt 0) {
    throw 'SETTINGS USER PREFERENCES BUTTON END ERROR.'
  }

  $insertAt = $buttonEnd + 20

  $button = @"
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const SecuritySessionsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.security_outlined),
                    label: const Text(
                      'Security and Sessions',
                    ),
                  ),
                ),
"@

  BackupFile $settingsPage
  WriteUtf8 $settingsPage (
    $settingsText.Substring(0,$insertAt) +
    $button +
    $settingsText.Substring($insertAt)
  )
}

& dart format `
  lib/features/settings `
  lib/core/constants/firestore_paths.dart `
  lib/core/di/service_locator.dart

if ($LASTEXITCODE -ne 0) {
  throw "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze `
  lib/features/settings `
  --no-fatal-infos `
  --no-fatal-warnings

if ($LASTEXITCODE -ne 0) {
  throw "SETTINGS ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Settings Phase 4 Security and Sessions installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Note: Active session and login history collections require login/logout tracking integration.' -ForegroundColor Yellow
Write-Host 'True remote token invalidation requires Firebase Admin SDK on the server.' -ForegroundColor Yellow
