[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\settings_phase3_$stamp"

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

if (Test-Path (FullPath 'lib/features/settings/domain/entities/user_preferences_entity.dart')) {
  throw 'EXISTING FILE ERROR: Settings Phase 3 appears already installed.'
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($path in $required) { BackupFile $path }

WriteUtf8 'lib/features/settings/domain/entities/user_preferences_entity.dart' @'
import 'package:equatable/equatable.dart';

enum AppThemePreference {
  system,
  light,
  dark,
}

class UserPreferencesEntity extends Equatable {
  const UserPreferencesEntity({
    required this.id,
    required this.userId,
    required this.theme,
    required this.defaultLandingPage,
    required this.rememberLastScreen,
    required this.pushNotifications,
    required this.homeworkNotifications,
    required this.attendanceNotifications,
    required this.feeNotifications,
    required this.examNotifications,
    required this.paperSize,
    required this.receiptFormat,
    required this.resultCardFormat,
    required this.language,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final AppThemePreference theme;
  final String defaultLandingPage;
  final bool rememberLastScreen;
  final bool pushNotifications;
  final bool homeworkNotifications;
  final bool attendanceNotifications;
  final bool feeNotifications;
  final bool examNotifications;
  final String paperSize;
  final String receiptFormat;
  final String resultCardFormat;
  final String language;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        theme,
        defaultLandingPage,
        rememberLastScreen,
        pushNotifications,
        homeworkNotifications,
        attendanceNotifications,
        feeNotifications,
        examNotifications,
        paperSize,
        receiptFormat,
        resultCardFormat,
        language,
        updatedAt,
      ];
}
'@

WriteUtf8 'lib/features/settings/data/models/user_preferences_model.dart' @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_preferences_entity.dart';

class UserPreferencesModel extends UserPreferencesEntity {
  const UserPreferencesModel({
    required super.id,
    required super.userId,
    required super.theme,
    required super.defaultLandingPage,
    required super.rememberLastScreen,
    required super.pushNotifications,
    required super.homeworkNotifications,
    required super.attendanceNotifications,
    required super.feeNotifications,
    required super.examNotifications,
    required super.paperSize,
    required super.receiptFormat,
    required super.resultCardFormat,
    required super.language,
    required super.updatedAt,
  });

  factory UserPreferencesModel.fromEntity(
    UserPreferencesEntity entity,
  ) {
    return UserPreferencesModel(
      id: entity.id,
      userId: entity.userId,
      theme: entity.theme,
      defaultLandingPage: entity.defaultLandingPage,
      rememberLastScreen: entity.rememberLastScreen,
      pushNotifications: entity.pushNotifications,
      homeworkNotifications: entity.homeworkNotifications,
      attendanceNotifications: entity.attendanceNotifications,
      feeNotifications: entity.feeNotifications,
      examNotifications: entity.examNotifications,
      paperSize: entity.paperSize,
      receiptFormat: entity.receiptFormat,
      resultCardFormat: entity.resultCardFormat,
      language: entity.language,
      updatedAt: entity.updatedAt,
    );
  }

  factory UserPreferencesModel.fromMap(
    Map<String, dynamic> map,
  ) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return UserPreferencesModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      theme: AppThemePreference.values.firstWhere(
        (item) => item.name == map['theme'],
        orElse: () => AppThemePreference.system,
      ),
      defaultLandingPage:
          map['defaultLandingPage'] as String? ?? 'dashboard',
      rememberLastScreen:
          map['rememberLastScreen'] as bool? ?? true,
      pushNotifications:
          map['pushNotifications'] as bool? ?? true,
      homeworkNotifications:
          map['homeworkNotifications'] as bool? ?? true,
      attendanceNotifications:
          map['attendanceNotifications'] as bool? ?? true,
      feeNotifications:
          map['feeNotifications'] as bool? ?? true,
      examNotifications:
          map['examNotifications'] as bool? ?? true,
      paperSize: map['paperSize'] as String? ?? 'A4',
      receiptFormat:
          map['receiptFormat'] as String? ?? 'Standard',
      resultCardFormat:
          map['resultCardFormat'] as String? ?? 'Standard',
      language: map['language'] as String? ?? 'English',
      updatedAt: date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'theme': theme.name,
        'defaultLandingPage': defaultLandingPage,
        'rememberLastScreen': rememberLastScreen,
        'pushNotifications': pushNotifications,
        'homeworkNotifications': homeworkNotifications,
        'attendanceNotifications': attendanceNotifications,
        'feeNotifications': feeNotifications,
        'examNotifications': examNotifications,
        'paperSize': paperSize,
        'receiptFormat': receiptFormat,
        'resultCardFormat': resultCardFormat,
        'language': language,
        'updatedAt': updatedAt.toIso8601String(),
        'schemaVersion': 1,
      };
}
'@

WriteUtf8 'lib/features/settings/domain/repositories/user_preferences_repository.dart' @'
import '../entities/user_preferences_entity.dart';

abstract class UserPreferencesRepository {
  Future<UserPreferencesEntity> getPreferences(String userId);

  Future<void> savePreferences(
    UserPreferencesEntity preferences,
  );
}
'@

WriteUtf8 'lib/features/settings/data/datasources/user_preferences_remote_datasource.dart' @'
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/user_preferences_entity.dart';
import '../models/user_preferences_model.dart';

abstract class UserPreferencesRemoteDataSource {
  Future<UserPreferencesEntity> getPreferences(String userId);

  Future<void> savePreferences(
    UserPreferencesEntity preferences,
  );
}

class UserPreferencesRemoteDataSourceImpl
    implements UserPreferencesRemoteDataSource {
  const UserPreferencesRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<UserPreferencesEntity> getPreferences(
    String userId,
  ) async {
    final id = userId.trim().isEmpty ? 'default' : userId;

    final document = await _service
        .collection(FirestorePaths.userPreferences)
        .doc(id)
        .get();

    if (!document.exists) {
      return UserPreferencesEntity(
        id: id,
        userId: userId,
        theme: AppThemePreference.system,
        defaultLandingPage: 'dashboard',
        rememberLastScreen: true,
        pushNotifications: true,
        homeworkNotifications: true,
        attendanceNotifications: true,
        feeNotifications: true,
        examNotifications: true,
        paperSize: 'A4',
        receiptFormat: 'Standard',
        resultCardFormat: 'Standard',
        language: 'English',
        updatedAt: DateTime.now(),
      );
    }

    return UserPreferencesModel.fromMap({
      ...document.data()!,
      'id': document.id,
    });
  }

  @override
  Future<void> savePreferences(
    UserPreferencesEntity preferences,
  ) {
    return _service
        .collection(FirestorePaths.userPreferences)
        .doc(preferences.id)
        .set(
          UserPreferencesModel.fromEntity(
            preferences,
          ).toMap(),
        );
  }
}
'@

WriteUtf8 'lib/features/settings/data/repositories/user_preferences_repository_impl.dart' @'
import '../../domain/entities/user_preferences_entity.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../datasources/user_preferences_remote_datasource.dart';

class UserPreferencesRepositoryImpl
    implements UserPreferencesRepository {
  const UserPreferencesRepositoryImpl(this._source);

  final UserPreferencesRemoteDataSource _source;

  @override
  Future<UserPreferencesEntity> getPreferences(
    String userId,
  ) {
    return _source.getPreferences(userId);
  }

  @override
  Future<void> savePreferences(
    UserPreferencesEntity preferences,
  ) {
    return _source.savePreferences(preferences);
  }
}
'@

WriteUtf8 'lib/features/settings/domain/usecases/manage_user_preferences.dart' @'
import '../entities/user_preferences_entity.dart';
import '../repositories/user_preferences_repository.dart';

class GetUserPreferences {
  const GetUserPreferences(this._repository);

  final UserPreferencesRepository _repository;

  Future<UserPreferencesEntity> call(String userId) {
    return _repository.getPreferences(userId);
  }
}

class SaveUserPreferences {
  const SaveUserPreferences(this._repository);

  final UserPreferencesRepository _repository;

  Future<void> call(UserPreferencesEntity preferences) {
    if (preferences.id.trim().isEmpty) {
      throw ArgumentError('Preference ID is required.');
    }

    return _repository.savePreferences(preferences);
  }
}
'@

WriteUtf8 'lib/features/settings/presentation/bloc/user_preferences_event.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/user_preferences_entity.dart';

sealed class UserPreferencesEvent extends Equatable {
  const UserPreferencesEvent();

  @override
  List<Object?> get props => const [];
}

class LoadUserPreferences extends UserPreferencesEvent {
  const LoadUserPreferences(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class SaveUserPreferencesRequested
    extends UserPreferencesEvent {
  const SaveUserPreferencesRequested(this.preferences);

  final UserPreferencesEntity preferences;

  @override
  List<Object?> get props => [preferences];
}
'@

WriteUtf8 'lib/features/settings/presentation/bloc/user_preferences_state.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/user_preferences_entity.dart';

sealed class UserPreferencesState extends Equatable {
  const UserPreferencesState();

  @override
  List<Object?> get props => const [];
}

class UserPreferencesInitial
    extends UserPreferencesState {
  const UserPreferencesInitial();
}

class UserPreferencesLoading
    extends UserPreferencesState {
  const UserPreferencesLoading();
}

class UserPreferencesLoaded
    extends UserPreferencesState {
  const UserPreferencesLoaded({
    required this.preferences,
    this.isSaving = false,
    this.message,
  });

  final UserPreferencesEntity preferences;
  final bool isSaving;
  final String? message;

  @override
  List<Object?> get props => [
        preferences,
        isSaving,
        message,
      ];
}

class UserPreferencesFailure
    extends UserPreferencesState {
  const UserPreferencesFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
'@

WriteUtf8 'lib/features/settings/presentation/bloc/user_preferences_bloc.dart' @'
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_user_preferences.dart';
import 'user_preferences_event.dart';
import 'user_preferences_state.dart';

class UserPreferencesBloc extends Bloc<
    UserPreferencesEvent,
    UserPreferencesState> {
  UserPreferencesBloc({
    required GetUserPreferences getPreferences,
    required SaveUserPreferences savePreferences,
  })  : _getPreferences = getPreferences,
        _savePreferences = savePreferences,
        super(const UserPreferencesInitial()) {
    on<LoadUserPreferences>(_load);
    on<SaveUserPreferencesRequested>(_save);
  }

  final GetUserPreferences _getPreferences;
  final SaveUserPreferences _savePreferences;

  Future<void> _load(
    LoadUserPreferences event,
    Emitter<UserPreferencesState> emit,
  ) async {
    emit(const UserPreferencesLoading());

    try {
      emit(
        UserPreferencesLoaded(
          preferences:
              await _getPreferences(event.userId),
        ),
      );
    } catch (error) {
      emit(
        UserPreferencesFailure(
          _message(error),
        ),
      );
    }
  }

  Future<void> _save(
    SaveUserPreferencesRequested event,
    Emitter<UserPreferencesState> emit,
  ) async {
    emit(
      UserPreferencesLoaded(
        preferences: event.preferences,
        isSaving: true,
      ),
    );

    try {
      await _savePreferences(event.preferences);

      emit(
        UserPreferencesLoaded(
          preferences: event.preferences,
          message: 'Preferences saved successfully.',
        ),
      );
    } catch (error) {
      emit(
        UserPreferencesFailure(
          _message(error),
        ),
      );
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
'@

WriteUtf8 'lib/features/settings/presentation/pages/user_preferences_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/user_preferences_entity.dart';
import '../bloc/user_preferences_bloc.dart';
import '../bloc/user_preferences_event.dart';
import '../bloc/user_preferences_state.dart';

class UserPreferencesPage extends StatelessWidget {
  const UserPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =
        sl<GetCurrentUserUseCase>()()?.uid ?? '';

    return BlocProvider(
      create: (_) => sl<UserPreferencesBloc>()
        ..add(LoadUserPreferences(userId)),
      child: const _UserPreferencesView(),
    );
  }
}

class _UserPreferencesView extends StatefulWidget {
  const _UserPreferencesView();

  @override
  State<_UserPreferencesView> createState() =>
      _UserPreferencesViewState();
}

class _UserPreferencesViewState
    extends State<_UserPreferencesView> {
  bool _initialized = false;

  AppThemePreference _theme =
      AppThemePreference.system;
  String _landingPage = 'dashboard';
  bool _rememberLastScreen = true;
  bool _pushNotifications = true;
  bool _homeworkNotifications = true;
  bool _attendanceNotifications = true;
  bool _feeNotifications = true;
  bool _examNotifications = true;
  String _paperSize = 'A4';
  String _receiptFormat = 'Standard';
  String _resultCardFormat = 'Standard';
  String _language = 'English';

  void _fill(UserPreferencesEntity preferences) {
    if (_initialized) return;

    _theme = preferences.theme;
    _landingPage = preferences.defaultLandingPage;
    _rememberLastScreen =
        preferences.rememberLastScreen;
    _pushNotifications =
        preferences.pushNotifications;
    _homeworkNotifications =
        preferences.homeworkNotifications;
    _attendanceNotifications =
        preferences.attendanceNotifications;
    _feeNotifications =
        preferences.feeNotifications;
    _examNotifications =
        preferences.examNotifications;
    _paperSize = preferences.paperSize;
    _receiptFormat = preferences.receiptFormat;
    _resultCardFormat =
        preferences.resultCardFormat;
    _language = preferences.language;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Preferences'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<
          UserPreferencesBloc,
          UserPreferencesState>(
        listener: (context, state) {
          if (state is UserPreferencesLoaded &&
              state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if (state is UserPreferencesInitial ||
              state is UserPreferencesLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is UserPreferencesFailure) {
            return Center(child: Text(state.message));
          }

          final loaded =
              state as UserPreferencesLoaded;
          _fill(loaded.preferences);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _section(
                context,
                title: 'Appearance',
                children: [
                  DropdownButtonFormField<
                      AppThemePreference>(
                    initialValue: _theme,
                    decoration: const InputDecoration(
                      labelText: 'Theme',
                    ),
                    items: AppThemePreference.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _theme = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _section(
                context,
                title: 'Dashboard',
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _landingPage,
                    decoration: const InputDecoration(
                      labelText: 'Default Landing Page',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'dashboard',
                        child: Text('Dashboard'),
                      ),
                      DropdownMenuItem(
                        value: 'students',
                        child: Text('Students'),
                      ),
                      DropdownMenuItem(
                        value: 'attendance',
                        child: Text('Attendance'),
                      ),
                      DropdownMenuItem(
                        value: 'fees',
                        child: Text('Fee Management'),
                      ),
                      DropdownMenuItem(
                        value: 'accounts',
                        child: Text('Accounts'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(
                          () => _landingPage = value,
                        );
                      }
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Remember Last Open Screen',
                    ),
                    value: _rememberLastScreen,
                    onChanged: (value) {
                      setState(
                        () => _rememberLastScreen = value,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _section(
                context,
                title: 'Notifications',
                children: [
                  _switch(
                    'Push Notifications',
                    _pushNotifications,
                    (value) => _pushNotifications = value,
                  ),
                  _switch(
                    'Homework Notifications',
                    _homeworkNotifications,
                    (value) =>
                        _homeworkNotifications = value,
                  ),
                  _switch(
                    'Attendance Notifications',
                    _attendanceNotifications,
                    (value) =>
                        _attendanceNotifications = value,
                  ),
                  _switch(
                    'Fee Reminder Notifications',
                    _feeNotifications,
                    (value) => _feeNotifications = value,
                  ),
                  _switch(
                    'Exam Notifications',
                    _examNotifications,
                    (value) => _examNotifications = value,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _section(
                context,
                title: 'Printing',
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _paperSize,
                    decoration: const InputDecoration(
                      labelText: 'Default Paper Size',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'A4',
                        child: Text('A4'),
                      ),
                      DropdownMenuItem(
                        value: 'A5',
                        child: Text('A5'),
                      ),
                      DropdownMenuItem(
                        value: 'Letter',
                        child: Text('Letter'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _paperSize = value);
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _receiptFormat,
                    decoration: const InputDecoration(
                      labelText: 'Receipt Format',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Standard',
                        child: Text('Standard'),
                      ),
                      DropdownMenuItem(
                        value: 'Compact',
                        child: Text('Compact'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(
                          () => _receiptFormat = value,
                        );
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _resultCardFormat,
                    decoration: const InputDecoration(
                      labelText: 'Result Card Format',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Standard',
                        child: Text('Standard'),
                      ),
                      DropdownMenuItem(
                        value: 'Detailed',
                        child: Text('Detailed'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(
                          () => _resultCardFormat = value,
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _section(
                context,
                title: 'General',
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _language,
                    decoration: const InputDecoration(
                      labelText: 'Language',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'English',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: 'Urdu',
                        child: Text('Urdu - Future Ready'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _language = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: loaded.isSaving
                      ? null
                      : () => _save(
                            context,
                            loaded.preferences,
                          ),
                  icon: loaded.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Preferences'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 14),
            ...children.map(
              (child) => Padding(
                padding:
                    const EdgeInsets.only(bottom: 10),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switch(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: (newValue) {
        setState(() => onChanged(newValue));
      },
    );
  }

  void _save(
    BuildContext context,
    UserPreferencesEntity current,
  ) {
    context.read<UserPreferencesBloc>().add(
          SaveUserPreferencesRequested(
            UserPreferencesEntity(
              id: current.id,
              userId: current.userId,
              theme: _theme,
              defaultLandingPage: _landingPage,
              rememberLastScreen:
                  _rememberLastScreen,
              pushNotifications:
                  _pushNotifications,
              homeworkNotifications:
                  _homeworkNotifications,
              attendanceNotifications:
                  _attendanceNotifications,
              feeNotifications: _feeNotifications,
              examNotifications: _examNotifications,
              paperSize: _paperSize,
              receiptFormat: _receiptFormat,
              resultCardFormat:
                  _resultCardFormat,
              language: _language,
              updatedAt: DateTime.now(),
            ),
          ),
        );
  }
}
'@

$pathsFile = 'lib/core/constants/firestore_paths.dart'
$pathsText = ReadUtf8 $pathsFile

if (-not $pathsText.Contains(
  'static const String userPreferences'
)) {
  $anchor = "  static const String systemSettings = 'system_settings';"

  if (-not $pathsText.Contains($anchor)) {
    throw 'FIRESTORE PATH ANCHOR ERROR.'
  }

  BackupFile $pathsFile

  WriteUtf8 $pathsFile (
    $pathsText.Replace(
      $anchor,
      "$anchor`n  static const String userPreferences = 'user_preferences';"
    )
  )
}

$slFile = 'lib/core/di/service_locator.dart'
$slText = ReadUtf8 $slFile

$imports = @"
import '../../features/settings/data/datasources/user_preferences_remote_datasource.dart';
import '../../features/settings/data/repositories/user_preferences_repository_impl.dart';
import '../../features/settings/domain/repositories/user_preferences_repository.dart';
import '../../features/settings/domain/usecases/manage_user_preferences.dart';
import '../../features/settings/presentation/bloc/user_preferences_bloc.dart';
"@

if (-not $slText.Contains(
  'user_preferences_remote_datasource.dart'
)) {
  InsertBefore `
    $slFile `
    "import '../../features/settings/data/datasources/settings_remote_datasource.dart';" `
    $imports
}

$registrations = @"
  sl.registerLazySingleton<UserPreferencesRemoteDataSource>(
    () => UserPreferencesRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<UserPreferencesRepository>(
    () => UserPreferencesRepositoryImpl(
      sl<UserPreferencesRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetUserPreferences>(
    () => GetUserPreferences(
      sl<UserPreferencesRepository>(),
    ),
  );
  sl.registerLazySingleton<SaveUserPreferences>(
    () => SaveUserPreferences(
      sl<UserPreferencesRepository>(),
    ),
  );
  sl.registerFactory<UserPreferencesBloc>(
    () => UserPreferencesBloc(
      getPreferences: sl<GetUserPreferences>(),
      savePreferences: sl<SaveUserPreferences>(),
    ),
  );

"@

if (-not $slText.Contains(
  'sl.registerLazySingleton<UserPreferencesRepository>'
)) {
  InsertBefore `
    $slFile `
    '  sl.registerLazySingleton<SettingsRemoteDataSource>(' `
    $registrations
}

$settingsPage = 'lib/features/settings/presentation/pages/settings_dashboard_page.dart'
$settingsText = ReadUtf8 $settingsPage

if (-not $settingsText.Contains(
  "import 'user_preferences_page.dart';"
)) {
  $anchor = "import 'backup_restore_page.dart';"

  if (-not $settingsText.Contains($anchor)) {
    throw 'SETTINGS PAGE IMPORT ANCHOR ERROR.'
  }

  BackupFile $settingsPage

  WriteUtf8 $settingsPage (
    $settingsText.Replace(
      $anchor,
      "$anchor`nimport 'user_preferences_page.dart';"
    )
  )
}

$settingsText = ReadUtf8 $settingsPage

if (-not $settingsText.Contains(
  'const UserPreferencesPage()'
)) {
  $anchor = "label: const Text('Backup and Restore'),"
  $index = $settingsText.IndexOf(
    $anchor,
    [StringComparison]::Ordinal
  )

  if ($index -lt 0) {
    throw 'SETTINGS USER PREFERENCES BUTTON ANCHOR ERROR.'
  }

  $buttonEnd = $settingsText.IndexOf(
    "`n                ),",
    $index,
    [StringComparison]::Ordinal
  )

  if ($buttonEnd -lt 0) {
    throw 'SETTINGS BACKUP BUTTON END ERROR.'
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
                              const UserPreferencesPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune_outlined),
                    label: const Text('User Preferences'),
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
Write-Host 'Settings Phase 3 User Preferences installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Note: Preferences are stored in Firestore.' -ForegroundColor Yellow
Write-Host 'Global app theme application can be connected during final UI polish.' -ForegroundColor Yellow
