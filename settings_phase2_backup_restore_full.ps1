[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\settings_phase2_$stamp"

function Full([string]$p) { Join-Path $root $p }
function ReadText([string]$p) { [IO.File]::ReadAllText((Full $p)) }
function WriteText([string]$p,[string]$t) {
  $f = Full $p
  $d = Split-Path $f -Parent
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
  [IO.File]::WriteAllText($f,$t.Replace("`r`n","`n"),$utf8)
}
function BackupFile([string]$p) {
  $s = Full $p
  if (-not (Test-Path $s)) { return }
  $t = Join-Path $backup $p
  $d = Split-Path $t -Parent
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
  Copy-Item $s $t -Force
}
function InsertBefore([string]$p,[string]$a,[string]$v) {
  $t = ReadText $p
  if ($t.Contains($v.Trim())) { return }
  $i = $t.IndexOf($a,[StringComparison]::Ordinal)
  if ($i -lt 0) { throw "ANCHOR ERROR in $p : $a" }
  BackupFile $p
  WriteText $p ($t.Substring(0,$i) + $v + $t.Substring($i))
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run from Flutter project root.'
}

$required = @(
  'lib/features/settings/presentation/pages/settings_dashboard_page.dart',
  'lib/core/constants/firestore_paths.dart',
  'lib/core/di/service_locator.dart',
  'lib/core/services/firebase_firestore_service.dart'
)

foreach ($p in $required) {
  if (-not (Test-Path (Full $p))) { throw "REQUIRED FILE ERROR: $p" }
}

if (Test-Path (Full 'lib/features/settings/domain/entities/backup_record_entity.dart')) {
  throw 'EXISTING FILE ERROR: Settings Phase 2 appears already installed.'
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($p in $required) { BackupFile $p }

WriteText 'lib/features/settings/domain/entities/backup_record_entity.dart' @'
import 'package:equatable/equatable.dart';

enum BackupStatus { requested, processing, completed, failed }

class BackupRecordEntity extends Equatable {
  const BackupRecordEntity({
    required this.id,
    required this.requestedBy,
    required this.requestedAt,
    required this.status,
    this.completedAt,
    this.fileName = '',
    this.fileUrl = '',
    this.notes = '',
    this.errorMessage = '',
  });

  final String id;
  final String requestedBy;
  final DateTime requestedAt;
  final BackupStatus status;
  final DateTime? completedAt;
  final String fileName;
  final String fileUrl;
  final String notes;
  final String errorMessage;

  @override
  List<Object?> get props => [
        id,
        requestedBy,
        requestedAt,
        status,
        completedAt,
        fileName,
        fileUrl,
        notes,
        errorMessage,
      ];
}
'@

WriteText 'lib/features/settings/domain/entities/restore_request_entity.dart' @'
import 'package:equatable/equatable.dart';

enum RestoreStatus { requested, approved, processing, completed, rejected, failed }

class RestoreRequestEntity extends Equatable {
  const RestoreRequestEntity({
    required this.id,
    required this.backupId,
    required this.backupFileName,
    required this.requestedBy,
    required this.requestedAt,
    required this.status,
    required this.confirmationText,
    this.notes = '',
  });

  final String id;
  final String backupId;
  final String backupFileName;
  final String requestedBy;
  final DateTime requestedAt;
  final RestoreStatus status;
  final String confirmationText;
  final String notes;

  @override
  List<Object?> get props => [
        id,
        backupId,
        backupFileName,
        requestedBy,
        requestedAt,
        status,
        confirmationText,
        notes,
      ];
}
'@

WriteText 'lib/features/settings/data/models/backup_models.dart' @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/backup_record_entity.dart';
import '../../domain/entities/restore_request_entity.dart';

DateTime _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse('$value') ?? DateTime.now();
}

class BackupRecordModel extends BackupRecordEntity {
  const BackupRecordModel({
    required super.id,
    required super.requestedBy,
    required super.requestedAt,
    required super.status,
    super.completedAt,
    super.fileName,
    super.fileUrl,
    super.notes,
    super.errorMessage,
  });

  factory BackupRecordModel.fromEntity(BackupRecordEntity e) =>
      BackupRecordModel(
        id: e.id,
        requestedBy: e.requestedBy,
        requestedAt: e.requestedAt,
        status: e.status,
        completedAt: e.completedAt,
        fileName: e.fileName,
        fileUrl: e.fileUrl,
        notes: e.notes,
        errorMessage: e.errorMessage,
      );

  factory BackupRecordModel.fromMap(Map<String, dynamic> map) =>
      BackupRecordModel(
        id: map['id'] as String? ?? '',
        requestedBy: map['requestedBy'] as String? ?? '',
        requestedAt: _date(map['requestedAt']),
        status: BackupStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => BackupStatus.requested,
        ),
        completedAt: map['completedAt'] == null ? null : _date(map['completedAt']),
        fileName: map['fileName'] as String? ?? '',
        fileUrl: map['fileUrl'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        errorMessage: map['errorMessage'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'requestedBy': requestedBy,
        'requestedAt': requestedAt.toIso8601String(),
        'status': status.name,
        'completedAt': completedAt?.toIso8601String(),
        'fileName': fileName,
        'fileUrl': fileUrl,
        'notes': notes,
        'errorMessage': errorMessage,
        'schemaVersion': 1,
      };
}

class RestoreRequestModel extends RestoreRequestEntity {
  const RestoreRequestModel({
    required super.id,
    required super.backupId,
    required super.backupFileName,
    required super.requestedBy,
    required super.requestedAt,
    required super.status,
    required super.confirmationText,
    super.notes,
  });

  factory RestoreRequestModel.fromEntity(RestoreRequestEntity e) =>
      RestoreRequestModel(
        id: e.id,
        backupId: e.backupId,
        backupFileName: e.backupFileName,
        requestedBy: e.requestedBy,
        requestedAt: e.requestedAt,
        status: e.status,
        confirmationText: e.confirmationText,
        notes: e.notes,
      );

  factory RestoreRequestModel.fromMap(Map<String, dynamic> map) =>
      RestoreRequestModel(
        id: map['id'] as String? ?? '',
        backupId: map['backupId'] as String? ?? '',
        backupFileName: map['backupFileName'] as String? ?? '',
        requestedBy: map['requestedBy'] as String? ?? '',
        requestedAt: _date(map['requestedAt']),
        status: RestoreStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => RestoreStatus.requested,
        ),
        confirmationText: map['confirmationText'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'backupId': backupId,
        'backupFileName': backupFileName,
        'requestedBy': requestedBy,
        'requestedAt': requestedAt.toIso8601String(),
        'status': status.name,
        'confirmationText': confirmationText,
        'notes': notes,
        'schemaVersion': 1,
      };
}
'@

WriteText 'lib/features/settings/domain/repositories/backup_repository.dart' @'
import '../entities/backup_record_entity.dart';
import '../entities/restore_request_entity.dart';

abstract class BackupRepository {
  Future<List<BackupRecordEntity>> getBackups();
  Future<List<RestoreRequestEntity>> getRestoreRequests();
  Future<void> requestBackup(String requestedBy, String notes);
  Future<void> requestRestore(RestoreRequestEntity request);
}
'@

WriteText 'lib/features/settings/data/datasources/backup_remote_datasource.dart' @'
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/backup_record_entity.dart';
import '../../domain/entities/restore_request_entity.dart';
import '../models/backup_models.dart';

abstract class BackupRemoteDataSource {
  Future<List<BackupRecordEntity>> getBackups();
  Future<List<RestoreRequestEntity>> getRestoreRequests();
  Future<void> requestBackup(String requestedBy, String notes);
  Future<void> requestRestore(RestoreRequestEntity request);
}

class BackupRemoteDataSourceImpl implements BackupRemoteDataSource {
  const BackupRemoteDataSourceImpl(this._firestore, this._functions);

  final FirebaseFirestoreService _firestore;
  final FirebaseFunctions _functions;

  @override
  Future<List<BackupRecordEntity>> getBackups() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.backupHistory)
        .get();

    final values = snapshot.docs
        .map((doc) => BackupRecordModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    values.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return values;
  }

  @override
  Future<List<RestoreRequestEntity>> getRestoreRequests() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.restoreRequests)
        .get();

    final values = snapshot.docs
        .map((doc) => RestoreRequestModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    values.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return values;
  }

  @override
  Future<void> requestBackup(String requestedBy, String notes) async {
    final now = DateTime.now();
    final id = 'backup_${now.microsecondsSinceEpoch}';

    final record = BackupRecordEntity(
      id: id,
      requestedBy: requestedBy,
      requestedAt: now,
      status: BackupStatus.requested,
      notes: notes,
    );

    await _firestore
        .collection(FirestorePaths.backupHistory)
        .doc(id)
        .set(BackupRecordModel.fromEntity(record).toMap());

    final callable = _functions.httpsCallable('createSchoolDataBackup');

    try {
      await callable.call<void>({
        'backupId': id,
        'requestedBy': requestedBy,
        'notes': notes,
      });
    } catch (error) {
      final failed = BackupRecordEntity(
        id: id,
        requestedBy: requestedBy,
        requestedAt: now,
        status: BackupStatus.failed,
        notes: notes,
        errorMessage: '$error',
      );

      await _firestore
          .collection(FirestorePaths.backupHistory)
          .doc(id)
          .set(BackupRecordModel.fromEntity(failed).toMap());

      rethrow;
    }
  }

  @override
  Future<void> requestRestore(RestoreRequestEntity request) {
    return _firestore
        .collection(FirestorePaths.restoreRequests)
        .doc(request.id)
        .set(RestoreRequestModel.fromEntity(request).toMap());
  }
}
'@

WriteText 'lib/features/settings/data/repositories/backup_repository_impl.dart' @'
import '../../domain/entities/backup_record_entity.dart';
import '../../domain/entities/restore_request_entity.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/backup_remote_datasource.dart';

class BackupRepositoryImpl implements BackupRepository {
  const BackupRepositoryImpl(this._source);

  final BackupRemoteDataSource _source;

  @override
  Future<List<BackupRecordEntity>> getBackups() => _source.getBackups();

  @override
  Future<List<RestoreRequestEntity>> getRestoreRequests() =>
      _source.getRestoreRequests();

  @override
  Future<void> requestBackup(String requestedBy, String notes) =>
      _source.requestBackup(requestedBy, notes);

  @override
  Future<void> requestRestore(RestoreRequestEntity request) =>
      _source.requestRestore(request);
}
'@

WriteText 'lib/features/settings/domain/usecases/manage_backup_restore.dart' @'
import '../entities/backup_record_entity.dart';
import '../entities/restore_request_entity.dart';
import '../repositories/backup_repository.dart';

class BackupRestoreData {
  const BackupRestoreData(this.backups, this.restoreRequests);

  final List<BackupRecordEntity> backups;
  final List<RestoreRequestEntity> restoreRequests;
}

class GetBackupRestoreData {
  const GetBackupRestoreData(this._repository);

  final BackupRepository _repository;

  Future<BackupRestoreData> call() async {
    final values = await Future.wait<Object>([
      _repository.getBackups(),
      _repository.getRestoreRequests(),
    ]);

    return BackupRestoreData(
      values[0] as List<BackupRecordEntity>,
      values[1] as List<RestoreRequestEntity>,
    );
  }
}

class RequestBackup {
  const RequestBackup(this._repository);

  final BackupRepository _repository;

  Future<void> call(String requestedBy, String notes) =>
      _repository.requestBackup(requestedBy, notes);
}

class RequestRestore {
  const RequestRestore(this._repository);

  final BackupRepository _repository;

  Future<void> call(RestoreRequestEntity request) {
    if (request.confirmationText.trim() != 'RESTORE') {
      throw ArgumentError('Type RESTORE to confirm.');
    }
    return _repository.requestRestore(request);
  }
}
'@

WriteText 'lib/features/settings/presentation/bloc/backup_event.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/restore_request_entity.dart';

sealed class BackupEvent extends Equatable {
  const BackupEvent();

  @override
  List<Object?> get props => const [];
}

class LoadBackupData extends BackupEvent {
  const LoadBackupData();
}

class CreateBackupRequested extends BackupEvent {
  const CreateBackupRequested(this.requestedBy, this.notes);

  final String requestedBy;
  final String notes;

  @override
  List<Object?> get props => [requestedBy, notes];
}

class CreateRestoreRequestRequested extends BackupEvent {
  const CreateRestoreRequestRequested(this.request);

  final RestoreRequestEntity request;

  @override
  List<Object?> get props => [request];
}
'@

WriteText 'lib/features/settings/presentation/bloc/backup_state.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/backup_record_entity.dart';
import '../../domain/entities/restore_request_entity.dart';

sealed class BackupState extends Equatable {
  const BackupState();

  @override
  List<Object?> get props => const [];
}

class BackupInitial extends BackupState {
  const BackupInitial();
}

class BackupLoading extends BackupState {
  const BackupLoading();
}

class BackupLoaded extends BackupState {
  const BackupLoaded({
    required this.backups,
    required this.restoreRequests,
    this.processing = false,
    this.message,
  });

  final List<BackupRecordEntity> backups;
  final List<RestoreRequestEntity> restoreRequests;
  final bool processing;
  final String? message;

  @override
  List<Object?> get props => [backups, restoreRequests, processing, message];
}

class BackupFailure extends BackupState {
  const BackupFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
'@

WriteText 'lib/features/settings/presentation/bloc/backup_bloc.dart' @'
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_backup_restore.dart';
import 'backup_event.dart';
import 'backup_state.dart';

class BackupBloc extends Bloc<BackupEvent, BackupState> {
  BackupBloc({
    required GetBackupRestoreData getData,
    required RequestBackup requestBackup,
    required RequestRestore requestRestore,
  })  : _getData = getData,
        _requestBackup = requestBackup,
        _requestRestore = requestRestore,
        super(const BackupInitial()) {
    on<LoadBackupData>(_load);
    on<CreateBackupRequested>(_backup);
    on<CreateRestoreRequestRequested>(_restore);
  }

  final GetBackupRestoreData _getData;
  final RequestBackup _requestBackup;
  final RequestRestore _requestRestore;

  Future<void> _load(LoadBackupData event, Emitter<BackupState> emit) async {
    emit(const BackupLoading());
    await _reload(emit);
  }

  Future<void> _backup(
    CreateBackupRequested event,
    Emitter<BackupState> emit,
  ) async {
    try {
      await _requestBackup(event.requestedBy, event.notes);
      await _reload(emit, message: 'Backup request submitted.');
    } catch (error) {
      emit(BackupFailure('$error'));
    }
  }

  Future<void> _restore(
    CreateRestoreRequestRequested event,
    Emitter<BackupState> emit,
  ) async {
    try {
      await _requestRestore(event.request);
      await _reload(emit, message: 'Restore request submitted.');
    } catch (error) {
      emit(BackupFailure('$error'));
    }
  }

  Future<void> _reload(
    Emitter<BackupState> emit, {
    String? message,
  }) async {
    try {
      final data = await _getData();
      emit(
        BackupLoaded(
          backups: data.backups,
          restoreRequests: data.restoreRequests,
          message: message,
        ),
      );
    } catch (error) {
      emit(BackupFailure('$error'));
    }
  }
}
'@

WriteText 'lib/features/settings/presentation/pages/backup_restore_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/backup_record_entity.dart';
import '../../domain/entities/restore_request_entity.dart';
import '../bloc/backup_bloc.dart';
import '../bloc/backup_event.dart';
import '../bloc/backup_state.dart';

class BackupRestorePage extends StatelessWidget {
  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BackupBloc>()..add(const LoadBackupData()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup and Restore'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<BackupBloc, BackupState>(
        listener: (context, state) {
          if (state is BackupLoaded && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if (state is BackupInitial || state is BackupLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BackupFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as BackupLoaded;
          final completed = data.backups
              .where((item) => item.status == BackupStatus.completed)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => _backup(context),
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('Create Backup'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: completed.isEmpty
                        ? null
                        : () => _restore(context, completed),
                    icon: const Icon(Icons.restore_outlined),
                    label: const Text('Request Restore'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Backup History', style: Theme.of(context).textTheme.titleLarge),
              if (data.backups.isEmpty)
                const Card(child: ListTile(title: Text('No backups found.'))),
              ...data.backups.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.fileName.isEmpty ? item.id : item.fileName),
                    subtitle: Text('${_date(item.requestedAt)} - ${item.status.name}'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Restore Requests', style: Theme.of(context).textTheme.titleLarge),
              if (data.restoreRequests.isEmpty)
                const Card(child: ListTile(title: Text('No restore requests found.'))),
              ...data.restoreRequests.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.backupFileName),
                    subtitle: Text('${_date(item.requestedAt)} - ${item.status.name}'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _backup(BuildContext context) async {
    final notes = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Backup'),
        content: TextField(
          controller: notes,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final user = sl<GetCurrentUserUseCase>()();
      context.read<BackupBloc>().add(
            CreateBackupRequested(
              user?.uid ?? '',
              notes.text.trim(),
            ),
          );
    }

    notes.dispose();
  }

  static Future<void> _restore(
    BuildContext context,
    List<BackupRecordEntity> backups,
  ) async {
    var selected = backups.first;
    final confirm = TextEditingController();
    final notes = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request Restore'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<BackupRecordEntity>(
                  initialValue: selected,
                  isExpanded: true,
                  items: backups
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.fileName.isEmpty ? e.id : e.fileName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selected = value);
                  },
                  decoration: const InputDecoration(labelText: 'Backup'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirm,
                  decoration: const InputDecoration(labelText: 'Type RESTORE'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      final now = DateTime.now();
      final user = sl<GetCurrentUserUseCase>()();

      context.read<BackupBloc>().add(
            CreateRestoreRequestRequested(
              RestoreRequestEntity(
                id: 'restore_${now.microsecondsSinceEpoch}',
                backupId: selected.id,
                backupFileName:
                    selected.fileName.isEmpty ? selected.id : selected.fileName,
                requestedBy: user?.uid ?? '',
                requestedAt: now,
                status: RestoreStatus.requested,
                confirmationText: confirm.text.trim(),
                notes: notes.text.trim(),
              ),
            ),
          );
    }

    confirm.dispose();
    notes.dispose();
  }

  static String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year}';
  }
}
'@

$paths = 'lib/core/constants/firestore_paths.dart'
$pathsText = ReadText $paths

if (-not $pathsText.Contains('static const String restoreRequests')) {
  $anchor = "  static const String backupHistory = 'backup_history';"
  if (-not $pathsText.Contains($anchor)) { throw 'FIRESTORE PATH ANCHOR ERROR.' }
  BackupFile $paths
  WriteText $paths ($pathsText.Replace(
    $anchor,
    "$anchor`n  static const String restoreRequests = 'restore_requests';"
  ))
}

$sl = 'lib/core/di/service_locator.dart'
$slText = ReadText $sl

$imports = @"
import '../../features/settings/data/datasources/backup_remote_datasource.dart';
import '../../features/settings/data/repositories/backup_repository_impl.dart';
import '../../features/settings/domain/repositories/backup_repository.dart';
import '../../features/settings/domain/usecases/manage_backup_restore.dart';
import '../../features/settings/presentation/bloc/backup_bloc.dart';
"@

if (-not $slText.Contains('backup_remote_datasource.dart')) {
  InsertBefore $sl "import '../../features/settings/data/datasources/settings_remote_datasource.dart';" $imports
}

$registrations = @"
  sl.registerLazySingleton<BackupRemoteDataSource>(
    () => BackupRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
      sl<FirebaseFunctions>(),
    ),
  );
  sl.registerLazySingleton<BackupRepository>(
    () => BackupRepositoryImpl(sl<BackupRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetBackupRestoreData>(
    () => GetBackupRestoreData(sl<BackupRepository>()),
  );
  sl.registerLazySingleton<RequestBackup>(
    () => RequestBackup(sl<BackupRepository>()),
  );
  sl.registerLazySingleton<RequestRestore>(
    () => RequestRestore(sl<BackupRepository>()),
  );
  sl.registerFactory<BackupBloc>(
    () => BackupBloc(
      getData: sl<GetBackupRestoreData>(),
      requestBackup: sl<RequestBackup>(),
      requestRestore: sl<RequestRestore>(),
    ),
  );

"@

if (-not $slText.Contains('sl.registerLazySingleton<BackupRepository>')) {
  InsertBefore $sl '  sl.registerLazySingleton<SettingsRemoteDataSource>(' $registrations
}

$page = 'lib/features/settings/presentation/pages/settings_dashboard_page.dart'
$pageText = ReadText $page

if (-not $pageText.Contains("import 'backup_restore_page.dart';")) {
  $anchor = "import '../bloc/settings_state.dart';"
  if (-not $pageText.Contains($anchor)) { throw 'SETTINGS IMPORT ANCHOR ERROR.' }
  BackupFile $page
  WriteText $page ($pageText.Replace(
    $anchor,
    "$anchor`nimport 'backup_restore_page.dart';"
  ))
}

$pageText = ReadText $page

if (-not $pageText.Contains('const BackupRestorePage()')) {
  $anchor = @"
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
"@

  $index = $pageText.IndexOf($anchor,[StringComparison]::Ordinal)
  if ($index -lt 0) { throw 'SETTINGS BACKUP BUTTON ANCHOR ERROR.' }

  $button = @"
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BackupRestorePage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('Backup and Restore'),
                  ),
                ),
"@

  BackupFile $page
  WriteText $page (
    $pageText.Substring(0,$index) +
    $button +
    $pageText.Substring($index)
  )
}

& dart format lib/features/settings lib/core/constants/firestore_paths.dart lib/core/di/service_locator.dart
if ($LASTEXITCODE -ne 0) { throw "DART FORMAT ERROR. Backup: $backup" }

& flutter analyze lib/features/settings --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) { throw "SETTINGS ANALYZE ERROR. Backup: $backup" }

Write-Host ''
Write-Host 'Settings Phase 2 Backup and Restore installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'IMPORTANT: Real backups require callable Cloud Function createSchoolDataBackup.' -ForegroundColor Yellow
Write-Host 'Restore execution must remain server-side and admin-controlled.' -ForegroundColor Yellow
