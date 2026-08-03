[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\settings_phase5_$stamp"

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

if (Test-Path (FullPath 'lib/features/settings/domain/entities/system_health_entity.dart')) {
  throw 'EXISTING FILE ERROR: Settings Phase 5 appears already installed.'
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($path in $required) { BackupFile $path }

WriteUtf8 'lib/features/settings/domain/entities/system_health_entity.dart' @'
import 'package:equatable/equatable.dart';

class SystemCollectionHealthEntity extends Equatable {
  const SystemCollectionHealthEntity({
    required this.name,
    required this.recordCount,
    required this.isReachable,
    this.errorMessage = '',
  });

  final String name;
  final int recordCount;
  final bool isReachable;
  final String errorMessage;

  @override
  List<Object?> get props => [
        name,
        recordCount,
        isReachable,
        errorMessage,
      ];
}

class SystemHealthEntity extends Equatable {
  const SystemHealthEntity({
    required this.checkedAt,
    required this.firestoreReachable,
    required this.authenticated,
    required this.currentUserId,
    required this.collections,
    required this.appVersion,
    required this.buildNumber,
    required this.firebaseProjectId,
    this.firestoreError = '',
  });

  final DateTime checkedAt;
  final bool firestoreReachable;
  final bool authenticated;
  final String currentUserId;
  final List<SystemCollectionHealthEntity> collections;
  final String appVersion;
  final String buildNumber;
  final String firebaseProjectId;
  final String firestoreError;

  int get totalRecords => collections.fold<int>(
        0,
        (sum, item) => sum + item.recordCount,
      );

  int get healthyCollections =>
      collections.where((item) => item.isReachable).length;

  @override
  List<Object?> get props => [
        checkedAt,
        firestoreReachable,
        authenticated,
        currentUserId,
        collections,
        appVersion,
        buildNumber,
        firebaseProjectId,
        firestoreError,
      ];
}
'@

WriteUtf8 'lib/features/settings/domain/repositories/system_health_repository.dart' @'
import '../entities/system_health_entity.dart';

abstract class SystemHealthRepository {
  Future<SystemHealthEntity> checkHealth();
  Future<void> writeHealthLog(SystemHealthEntity health);
}
'@

WriteUtf8 'lib/features/settings/data/datasources/system_health_remote_datasource.dart' @'
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/system_health_entity.dart';

abstract class SystemHealthRemoteDataSource {
  Future<SystemHealthEntity> checkHealth();
  Future<void> writeHealthLog(SystemHealthEntity health);
}

class SystemHealthRemoteDataSourceImpl
    implements SystemHealthRemoteDataSource {
  const SystemHealthRemoteDataSourceImpl(
    this._firestore,
    this._auth,
  );

  final FirebaseFirestoreService _firestore;
  final FirebaseAuth _auth;

  @override
  Future<SystemHealthEntity> checkHealth() async {
    final now = DateTime.now();
    final collections = <SystemCollectionHealthEntity>[];

    final collectionNames = <String>[
      FirestorePaths.students,
      FirestorePaths.attendance,
      FirestorePaths.homework,
      FirestorePaths.feePayments,
      FirestorePaths.exams,
      FirestorePaths.results,
      FirestorePaths.storeItems,
      FirestorePaths.storeSales,
      FirestorePaths.communicationMessages,
      FirestorePaths.systemSettings,
    ];

    var firestoreReachable = true;
    var firestoreError = '';

    for (final name in collectionNames) {
      try {
        final snapshot =
            await _firestore.collection(name).get();

        collections.add(
          SystemCollectionHealthEntity(
            name: name,
            recordCount: snapshot.docs.length,
            isReachable: true,
          ),
        );
      } catch (error) {
        firestoreReachable = false;
        firestoreError = '$error';

        collections.add(
          SystemCollectionHealthEntity(
            name: name,
            recordCount: 0,
            isReachable: false,
            errorMessage: '$error',
          ),
        );
      }
    }

    final user = _auth.currentUser;
    final app = Firebase.apps.isEmpty
        ? null
        : Firebase.app();

    return SystemHealthEntity(
      checkedAt: now,
      firestoreReachable: firestoreReachable,
      authenticated: user != null,
      currentUserId: user?.uid ?? '',
      collections: collections,
      appVersion: '1.0.0',
      buildNumber: '1',
      firebaseProjectId:
          app?.options.projectId ?? 'Unknown',
      firestoreError: firestoreError,
    );
  }

  @override
  Future<void> writeHealthLog(
    SystemHealthEntity health,
  ) {
    final id =
        'health_${health.checkedAt.microsecondsSinceEpoch}';

    return _firestore
        .collection(FirestorePaths.systemHealthLogs)
        .doc(id)
        .set({
      'id': id,
      'checkedAt': health.checkedAt.toIso8601String(),
      'firestoreReachable': health.firestoreReachable,
      'authenticated': health.authenticated,
      'currentUserId': health.currentUserId,
      'appVersion': health.appVersion,
      'buildNumber': health.buildNumber,
      'firebaseProjectId': health.firebaseProjectId,
      'totalRecords': health.totalRecords,
      'healthyCollections': health.healthyCollections,
      'firestoreError': health.firestoreError,
      'collections': health.collections
          .map(
            (item) => {
              'name': item.name,
              'recordCount': item.recordCount,
              'isReachable': item.isReachable,
              'errorMessage': item.errorMessage,
            },
          )
          .toList(),
      'schemaVersion': 1,
    });
  }
}
'@

WriteUtf8 'lib/features/settings/data/repositories/system_health_repository_impl.dart' @'
import '../../domain/entities/system_health_entity.dart';
import '../../domain/repositories/system_health_repository.dart';
import '../datasources/system_health_remote_datasource.dart';

class SystemHealthRepositoryImpl
    implements SystemHealthRepository {
  const SystemHealthRepositoryImpl(this._source);

  final SystemHealthRemoteDataSource _source;

  @override
  Future<SystemHealthEntity> checkHealth() {
    return _source.checkHealth();
  }

  @override
  Future<void> writeHealthLog(
    SystemHealthEntity health,
  ) {
    return _source.writeHealthLog(health);
  }
}
'@

WriteUtf8 'lib/features/settings/domain/usecases/manage_system_health.dart' @'
import '../entities/system_health_entity.dart';
import '../repositories/system_health_repository.dart';

class CheckSystemHealth {
  const CheckSystemHealth(this._repository);

  final SystemHealthRepository _repository;

  Future<SystemHealthEntity> call() async {
    final health = await _repository.checkHealth();
    await _repository.writeHealthLog(health);
    return health;
  }
}
'@

WriteUtf8 'lib/features/settings/presentation/bloc/system_health_event.dart' @'
import 'package:equatable/equatable.dart';

sealed class SystemHealthEvent extends Equatable {
  const SystemHealthEvent();

  @override
  List<Object?> get props => const [];
}

class LoadSystemHealth extends SystemHealthEvent {
  const LoadSystemHealth();
}

class RefreshSystemHealth extends SystemHealthEvent {
  const RefreshSystemHealth();
}
'@

WriteUtf8 'lib/features/settings/presentation/bloc/system_health_state.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/system_health_entity.dart';

sealed class SystemHealthState extends Equatable {
  const SystemHealthState();

  @override
  List<Object?> get props => const [];
}

class SystemHealthInitial extends SystemHealthState {
  const SystemHealthInitial();
}

class SystemHealthLoading extends SystemHealthState {
  const SystemHealthLoading();
}

class SystemHealthLoaded extends SystemHealthState {
  const SystemHealthLoaded(this.health);

  final SystemHealthEntity health;

  @override
  List<Object?> get props => [health];
}

class SystemHealthFailure extends SystemHealthState {
  const SystemHealthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
'@

WriteUtf8 'lib/features/settings/presentation/bloc/system_health_bloc.dart' @'
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_system_health.dart';
import 'system_health_event.dart';
import 'system_health_state.dart';

class SystemHealthBloc
    extends Bloc<SystemHealthEvent, SystemHealthState> {
  SystemHealthBloc(this._checkHealth)
      : super(const SystemHealthInitial()) {
    on<LoadSystemHealth>(_load);
    on<RefreshSystemHealth>(_refresh);
  }

  final CheckSystemHealth _checkHealth;

  Future<void> _load(
    LoadSystemHealth event,
    Emitter<SystemHealthState> emit,
  ) async {
    emit(const SystemHealthLoading());
    await _run(emit);
  }

  Future<void> _refresh(
    RefreshSystemHealth event,
    Emitter<SystemHealthState> emit,
  ) async {
    emit(const SystemHealthLoading());
    await _run(emit);
  }

  Future<void> _run(
    Emitter<SystemHealthState> emit,
  ) async {
    try {
      emit(
        SystemHealthLoaded(
          await _checkHealth(),
        ),
      );
    } catch (error) {
      emit(
        SystemHealthFailure(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
'@

WriteUtf8 'lib/features/settings/presentation/pages/system_health_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../bloc/system_health_bloc.dart';
import '../bloc/system_health_event.dart';
import '../bloc/system_health_state.dart';

class SystemHealthPage extends StatelessWidget {
  const SystemHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SystemHealthBloc>()
        ..add(const LoadSystemHealth()),
      child: const _SystemHealthView(),
    );
  }
}

class _SystemHealthView extends StatelessWidget {
  const _SystemHealthView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Health and Diagnostics'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocBuilder<
          SystemHealthBloc,
          SystemHealthState>(
        builder: (context, state) {
          if (state is SystemHealthInitial ||
              state is SystemHealthLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is SystemHealthFailure) {
            return Center(child: Text(state.message));
          }

          final health =
              (state as SystemHealthLoaded).health;

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<SystemHealthBloc>()
                  .add(const RefreshSystemHealth());
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      title: 'Firestore',
                      value: health.firestoreReachable
                          ? 'Connected'
                          : 'Error',
                    ),
                    _MetricCard(
                      title: 'Authentication',
                      value: health.authenticated
                          ? 'Signed In'
                          : 'Signed Out',
                    ),
                    _MetricCard(
                      title: 'Healthy Collections',
                      value:
                          '${health.healthyCollections}/${health.collections.length}',
                    ),
                    _MetricCard(
                      title: 'Total Records',
                      value: '${health.totalRecords}',
                    ),
                    _MetricCard(
                      title: 'App Version',
                      value:
                          '${health.appVersion}+${health.buildNumber}',
                    ),
                    _MetricCard(
                      title: 'Firebase Project',
                      value: health.firebaseProjectId,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      context
                          .read<SystemHealthBloc>()
                          .add(
                            const RefreshSystemHealth(),
                          );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Run Diagnostics'),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Collection Status',
                  style:
                      Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...health.collections.map(
                  (item) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          item.isReachable
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                        ),
                      ),
                      title: Text(item.name),
                      subtitle: item.errorMessage.isEmpty
                          ? null
                          : Text(item.errorMessage),
                      trailing: Text(
                        item.isReachable
                            ? '${item.recordCount} records'
                            : 'Unavailable',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'About ERP',
                  style:
                      Theme.of(context).textTheme.titleLarge,
                ),
                const Card(
                  child: ListTile(
                    title: Text('Almustafa Connect ERP'),
                    subtitle: Text(
                      'School Management System - Version 1.0',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Last Diagnostic Check'),
                    subtitle: Text(
                      _dateTime(health.checkedAt),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _dateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
'@

$pathsFile = 'lib/core/constants/firestore_paths.dart'
$pathsText = ReadUtf8 $pathsFile

if (-not $pathsText.Contains(
  'static const String systemHealthLogs'
)) {
  $anchor = "  static const String securityLogs = 'security_logs';"

  if (-not $pathsText.Contains($anchor)) {
    throw 'FIRESTORE PATH ANCHOR ERROR.'
  }

  BackupFile $pathsFile

  WriteUtf8 $pathsFile (
    $pathsText.Replace(
      $anchor,
      "$anchor`n  static const String systemHealthLogs = 'system_health_logs';"
    )
  )
}

$slFile = 'lib/core/di/service_locator.dart'
$slText = ReadUtf8 $slFile

$imports = @"
import '../../features/settings/data/datasources/system_health_remote_datasource.dart';
import '../../features/settings/data/repositories/system_health_repository_impl.dart';
import '../../features/settings/domain/repositories/system_health_repository.dart';
import '../../features/settings/domain/usecases/manage_system_health.dart';
import '../../features/settings/presentation/bloc/system_health_bloc.dart';
"@

if (-not $slText.Contains(
  'system_health_remote_datasource.dart'
)) {
  InsertBefore `
    $slFile `
    "import '../../features/settings/data/datasources/settings_remote_datasource.dart';" `
    $imports
}

$registrations = @"
  sl.registerLazySingleton<SystemHealthRemoteDataSource>(
    () => SystemHealthRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
      sl<FirebaseAuth>(),
    ),
  );
  sl.registerLazySingleton<SystemHealthRepository>(
    () => SystemHealthRepositoryImpl(
      sl<SystemHealthRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<CheckSystemHealth>(
    () => CheckSystemHealth(
      sl<SystemHealthRepository>(),
    ),
  );
  sl.registerFactory<SystemHealthBloc>(
    () => SystemHealthBloc(
      sl<CheckSystemHealth>(),
    ),
  );

"@

if (-not $slText.Contains(
  'sl.registerLazySingleton<SystemHealthRepository>'
)) {
  InsertBefore `
    $slFile `
    '  sl.registerLazySingleton<SettingsRemoteDataSource>(' `
    $registrations
}

$settingsPage = 'lib/features/settings/presentation/pages/settings_dashboard_page.dart'
$settingsText = ReadUtf8 $settingsPage

if (-not $settingsText.Contains(
  "import 'system_health_page.dart';"
)) {
  $anchor = "import 'security_sessions_page.dart';"

  if (-not $settingsText.Contains($anchor)) {
    throw 'SETTINGS PAGE IMPORT ANCHOR ERROR.'
  }

  BackupFile $settingsPage

  WriteUtf8 $settingsPage (
    $settingsText.Replace(
      $anchor,
      "$anchor`nimport 'system_health_page.dart';"
    )
  )
}

$settingsText = ReadUtf8 $settingsPage

if (-not $settingsText.Contains(
  'const SystemHealthPage()'
)) {
  $anchor = "label: const Text('Security and Sessions'),"
  $index = $settingsText.IndexOf(
    $anchor,
    [StringComparison]::Ordinal
  )

  if ($index -lt 0) {
    throw 'SETTINGS SYSTEM HEALTH BUTTON ANCHOR ERROR.'
  }

  $buttonEnd = $settingsText.IndexOf(
    "`n                ),",
    $index,
    [StringComparison]::Ordinal
  )

  if ($buttonEnd -lt 0) {
    throw 'SETTINGS SECURITY BUTTON END ERROR.'
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
                              const SystemHealthPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.monitor_heart_outlined,
                    ),
                    label: const Text(
                      'System Health and Diagnostics',
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
Write-Host 'Settings Phase 5 System Health and Diagnostics installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Functional ERP development is now complete.' -ForegroundColor Green
Write-Host 'Next stage: testing, UI polish, graphics, and release preparation.' -ForegroundColor Yellow
