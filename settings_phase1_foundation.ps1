[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\settings_phase1_$stamp"

function FullPath([string]$Path) { Join-Path $root $Path }
function ReadUtf8([string]$Path) {
  [IO.File]::ReadAllText((FullPath $Path))
}
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
  'lib/core/constants/firestore_paths.dart',
  'lib/core/di/service_locator.dart',
  'lib/core/services/firebase_firestore_service.dart'
)

foreach ($path in $required) {
  if (-not (Test-Path (FullPath $path))) {
    throw "REQUIRED FILE ERROR: $path"
  }
}

if (Test-Path (FullPath 'lib/features/settings')) {
  throw 'EXISTING MODULE ERROR: lib/features/settings already exists.'
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($path in $required) { BackupFile $path }

WriteUtf8 'lib/features/settings/domain/entities/school_settings_entity.dart' @'
import 'package:equatable/equatable.dart';

class SchoolSettingsEntity extends Equatable {
  const SchoolSettingsEntity({
    required this.id,
    required this.schoolName,
    required this.schoolCode,
    required this.currentSession,
    required this.sessionStartDate,
    required this.sessionEndDate,
    required this.currency,
    required this.currencySymbol,
    required this.dateFormat,
    required this.timeFormat,
    required this.admissionPrefix,
    required this.rollNumberPrefix,
    required this.receiptPrefix,
    required this.updatedAt,
    this.tagLine = '',
    this.address = '',
    this.city = '',
    this.country = 'Pakistan',
    this.phone = '',
    this.whatsApp = '',
    this.email = '',
    this.website = '',
    this.logoUrl = '',
    this.reportHeaderUrl = '',
    this.reportFooterUrl = '',
  });

  final String id;
  final String schoolName;
  final String schoolCode;
  final String currentSession;
  final DateTime sessionStartDate;
  final DateTime sessionEndDate;
  final String currency;
  final String currencySymbol;
  final String dateFormat;
  final String timeFormat;
  final String admissionPrefix;
  final String rollNumberPrefix;
  final String receiptPrefix;
  final DateTime updatedAt;
  final String tagLine;
  final String address;
  final String city;
  final String country;
  final String phone;
  final String whatsApp;
  final String email;
  final String website;
  final String logoUrl;
  final String reportHeaderUrl;
  final String reportFooterUrl;

  @override
  List<Object?> get props => [
        id,
        schoolName,
        schoolCode,
        currentSession,
        sessionStartDate,
        sessionEndDate,
        currency,
        currencySymbol,
        dateFormat,
        timeFormat,
        admissionPrefix,
        rollNumberPrefix,
        receiptPrefix,
        updatedAt,
        tagLine,
        address,
        city,
        country,
        phone,
        whatsApp,
        email,
        website,
        logoUrl,
        reportHeaderUrl,
        reportFooterUrl,
      ];
}
'@

WriteUtf8 'lib/features/settings/data/models/school_settings_model.dart' @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/school_settings_entity.dart';

class SchoolSettingsModel extends SchoolSettingsEntity {
  const SchoolSettingsModel({
    required super.id,
    required super.schoolName,
    required super.schoolCode,
    required super.currentSession,
    required super.sessionStartDate,
    required super.sessionEndDate,
    required super.currency,
    required super.currencySymbol,
    required super.dateFormat,
    required super.timeFormat,
    required super.admissionPrefix,
    required super.rollNumberPrefix,
    required super.receiptPrefix,
    required super.updatedAt,
    super.tagLine,
    super.address,
    super.city,
    super.country,
    super.phone,
    super.whatsApp,
    super.email,
    super.website,
    super.logoUrl,
    super.reportHeaderUrl,
    super.reportFooterUrl,
  });

  factory SchoolSettingsModel.fromEntity(
    SchoolSettingsEntity entity,
  ) {
    return SchoolSettingsModel(
      id: entity.id,
      schoolName: entity.schoolName,
      schoolCode: entity.schoolCode,
      currentSession: entity.currentSession,
      sessionStartDate: entity.sessionStartDate,
      sessionEndDate: entity.sessionEndDate,
      currency: entity.currency,
      currencySymbol: entity.currencySymbol,
      dateFormat: entity.dateFormat,
      timeFormat: entity.timeFormat,
      admissionPrefix: entity.admissionPrefix,
      rollNumberPrefix: entity.rollNumberPrefix,
      receiptPrefix: entity.receiptPrefix,
      updatedAt: entity.updatedAt,
      tagLine: entity.tagLine,
      address: entity.address,
      city: entity.city,
      country: entity.country,
      phone: entity.phone,
      whatsApp: entity.whatsApp,
      email: entity.email,
      website: entity.website,
      logoUrl: entity.logoUrl,
      reportHeaderUrl: entity.reportHeaderUrl,
      reportFooterUrl: entity.reportFooterUrl,
    );
  }

  factory SchoolSettingsModel.fromMap(
    Map<String, dynamic> map,
  ) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return SchoolSettingsModel(
      id: map['id'] as String? ?? 'default',
      schoolName:
          map['schoolName'] as String? ?? 'Almustafa Model School',
      schoolCode: map['schoolCode'] as String? ?? 'AMS',
      currentSession:
          map['currentSession'] as String? ?? '2026-2027',
      sessionStartDate: date(map['sessionStartDate']),
      sessionEndDate: date(map['sessionEndDate']),
      currency: map['currency'] as String? ?? 'PKR',
      currencySymbol: map['currencySymbol'] as String? ?? 'Rs.',
      dateFormat: map['dateFormat'] as String? ?? 'dd-MM-yyyy',
      timeFormat: map['timeFormat'] as String? ?? '12 Hour',
      admissionPrefix:
          map['admissionPrefix'] as String? ?? 'AMS',
      rollNumberPrefix:
          map['rollNumberPrefix'] as String? ?? '',
      receiptPrefix:
          map['receiptPrefix'] as String? ?? 'REC',
      updatedAt: date(map['updatedAt']),
      tagLine: map['tagLine'] as String? ?? '',
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? 'Multan',
      country: map['country'] as String? ?? 'Pakistan',
      phone: map['phone'] as String? ?? '',
      whatsApp: map['whatsApp'] as String? ?? '',
      email: map['email'] as String? ?? '',
      website: map['website'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
      reportHeaderUrl: map['reportHeaderUrl'] as String? ?? '',
      reportFooterUrl: map['reportFooterUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'schoolName': schoolName,
        'schoolCode': schoolCode,
        'currentSession': currentSession,
        'sessionStartDate': sessionStartDate.toIso8601String(),
        'sessionEndDate': sessionEndDate.toIso8601String(),
        'currency': currency,
        'currencySymbol': currencySymbol,
        'dateFormat': dateFormat,
        'timeFormat': timeFormat,
        'admissionPrefix': admissionPrefix,
        'rollNumberPrefix': rollNumberPrefix,
        'receiptPrefix': receiptPrefix,
        'updatedAt': updatedAt.toIso8601String(),
        'tagLine': tagLine,
        'address': address,
        'city': city,
        'country': country,
        'phone': phone,
        'whatsApp': whatsApp,
        'email': email,
        'website': website,
        'logoUrl': logoUrl,
        'reportHeaderUrl': reportHeaderUrl,
        'reportFooterUrl': reportFooterUrl,
        'schemaVersion': 1,
      };
}
'@

WriteUtf8 'lib/features/settings/domain/repositories/settings_repository.dart' @'
import '../entities/school_settings_entity.dart';

abstract class SettingsRepository {
  Future<SchoolSettingsEntity> getSettings();
  Future<void> saveSettings(SchoolSettingsEntity settings);
}
'@

WriteUtf8 'lib/features/settings/data/datasources/settings_remote_datasource.dart' @'
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/school_settings_entity.dart';
import '../models/school_settings_model.dart';

abstract class SettingsRemoteDataSource {
  Future<SchoolSettingsEntity> getSettings();
  Future<void> saveSettings(SchoolSettingsEntity settings);
}

class SettingsRemoteDataSourceImpl
    implements SettingsRemoteDataSource {
  const SettingsRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<SchoolSettingsEntity> getSettings() async {
    final document = await _service
        .collection(FirestorePaths.systemSettings)
        .doc('default')
        .get();

    if (!document.exists) {
      final now = DateTime.now();

      return SchoolSettingsEntity(
        id: 'default',
        schoolName: 'Almustafa Model School',
        schoolCode: 'AMS',
        currentSession: '2026-2027',
        sessionStartDate: DateTime(2026, 4, 1),
        sessionEndDate: DateTime(2027, 3, 31),
        currency: 'PKR',
        currencySymbol: 'Rs.',
        dateFormat: 'dd-MM-yyyy',
        timeFormat: '12 Hour',
        admissionPrefix: 'AMS',
        rollNumberPrefix: '',
        receiptPrefix: 'REC',
        updatedAt: now,
        city: 'Multan',
        country: 'Pakistan',
      );
    }

    return SchoolSettingsModel.fromMap({
      ...document.data()!,
      'id': document.id,
    });
  }

  @override
  Future<void> saveSettings(
    SchoolSettingsEntity settings,
  ) {
    return _service
        .collection(FirestorePaths.systemSettings)
        .doc(settings.id)
        .set(
          SchoolSettingsModel.fromEntity(settings).toMap(),
        );
  }
}
'@

WriteUtf8 'lib/features/settings/data/repositories/settings_repository_impl.dart' @'
import '../../domain/entities/school_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._source);

  final SettingsRemoteDataSource _source;

  @override
  Future<SchoolSettingsEntity> getSettings() {
    return _source.getSettings();
  }

  @override
  Future<void> saveSettings(
    SchoolSettingsEntity settings,
  ) {
    return _source.saveSettings(settings);
  }
}
'@

WriteUtf8 'lib/features/settings/domain/usecases/manage_settings.dart' @'
import '../entities/school_settings_entity.dart';
import '../repositories/settings_repository.dart';

class GetSchoolSettings {
  const GetSchoolSettings(this._repository);

  final SettingsRepository _repository;

  Future<SchoolSettingsEntity> call() {
    return _repository.getSettings();
  }
}

class SaveSchoolSettings {
  const SaveSchoolSettings(this._repository);

  final SettingsRepository _repository;

  Future<void> call(SchoolSettingsEntity settings) {
    if (settings.schoolName.trim().isEmpty) {
      throw ArgumentError('School name is required.');
    }
    if (settings.schoolCode.trim().isEmpty) {
      throw ArgumentError('School code is required.');
    }
    if (settings.currentSession.trim().isEmpty) {
      throw ArgumentError('Current session is required.');
    }
    if (!settings.sessionEndDate
        .isAfter(settings.sessionStartDate)) {
      throw ArgumentError(
        'Session end date must be after start date.',
      );
    }
    return _repository.saveSettings(settings);
  }
}
'@

WriteUtf8 'lib/features/settings/presentation/bloc/settings_event.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/school_settings_entity.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class SaveSettingsRequested extends SettingsEvent {
  const SaveSettingsRequested(this.settings);

  final SchoolSettingsEntity settings;

  @override
  List<Object?> get props => [settings];
}
'@

WriteUtf8 'lib/features/settings/presentation/bloc/settings_state.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/school_settings_entity.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => const [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded({
    required this.settings,
    this.isSaving = false,
    this.message,
  });

  final SchoolSettingsEntity settings;
  final bool isSaving;
  final String? message;

  @override
  List<Object?> get props => [
        settings,
        isSaving,
        message,
      ];
}

class SettingsFailure extends SettingsState {
  const SettingsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
'@

WriteUtf8 'lib/features/settings/presentation/bloc/settings_bloc.dart' @'
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_settings.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required GetSchoolSettings getSettings,
    required SaveSchoolSettings saveSettings,
  })  : _getSettings = getSettings,
        _saveSettings = saveSettings,
        super(const SettingsInitial()) {
    on<LoadSettings>(_load);
    on<SaveSettingsRequested>(_save);
  }

  final GetSchoolSettings _getSettings;
  final SaveSchoolSettings _saveSettings;

  Future<void> _load(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    try {
      emit(
        SettingsLoaded(
          settings: await _getSettings(),
        ),
      );
    } catch (error) {
      emit(SettingsFailure(_message(error)));
    }
  }

  Future<void> _save(
    SaveSettingsRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(
      SettingsLoaded(
        settings: event.settings,
        isSaving: true,
      ),
    );

    try {
      await _saveSettings(event.settings);

      emit(
        SettingsLoaded(
          settings: event.settings,
          message: 'Settings saved successfully.',
        ),
      );
    } catch (error) {
      emit(SettingsFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
'@

WriteUtf8 'lib/features/settings/presentation/pages/settings_dashboard_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/school_settings_entity.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsDashboardPage extends StatelessWidget {
  const SettingsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<SettingsBloc>()..add(const LoadSettings()),
      child: const _SettingsDashboardView(),
    );
  }
}

class _SettingsDashboardView extends StatefulWidget {
  const _SettingsDashboardView();

  @override
  State<_SettingsDashboardView> createState() =>
      _SettingsDashboardViewState();
}

class _SettingsDashboardViewState
    extends State<_SettingsDashboardView> {
  final _formKey = GlobalKey<FormState>();

  final _schoolName = TextEditingController();
  final _schoolCode = TextEditingController();
  final _session = TextEditingController();
  final _tagLine = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _phone = TextEditingController();
  final _whatsApp = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _admissionPrefix = TextEditingController();
  final _rollPrefix = TextEditingController();
  final _receiptPrefix = TextEditingController();
  final _logoUrl = TextEditingController();
  final _headerUrl = TextEditingController();
  final _footerUrl = TextEditingController();

  DateTime _sessionStart = DateTime(2026, 4, 1);
  DateTime _sessionEnd = DateTime(2027, 3, 31);
  String _currency = 'PKR';
  String _currencySymbol = 'Rs.';
  String _dateFormat = 'dd-MM-yyyy';
  String _timeFormat = '12 Hour';
  bool _initialized = false;

  @override
  void dispose() {
    _schoolName.dispose();
    _schoolCode.dispose();
    _session.dispose();
    _tagLine.dispose();
    _address.dispose();
    _city.dispose();
    _country.dispose();
    _phone.dispose();
    _whatsApp.dispose();
    _email.dispose();
    _website.dispose();
    _admissionPrefix.dispose();
    _rollPrefix.dispose();
    _receiptPrefix.dispose();
    _logoUrl.dispose();
    _headerUrl.dispose();
    _footerUrl.dispose();
    super.dispose();
  }

  void _fill(SchoolSettingsEntity value) {
    if (_initialized) return;

    _schoolName.text = value.schoolName;
    _schoolCode.text = value.schoolCode;
    _session.text = value.currentSession;
    _tagLine.text = value.tagLine;
    _address.text = value.address;
    _city.text = value.city;
    _country.text = value.country;
    _phone.text = value.phone;
    _whatsApp.text = value.whatsApp;
    _email.text = value.email;
    _website.text = value.website;
    _admissionPrefix.text = value.admissionPrefix;
    _rollPrefix.text = value.rollNumberPrefix;
    _receiptPrefix.text = value.receiptPrefix;
    _logoUrl.text = value.logoUrl;
    _headerUrl.text = value.reportHeaderUrl;
    _footerUrl.text = value.reportFooterUrl;
    _sessionStart = value.sessionStartDate;
    _sessionEnd = value.sessionEndDate;
    _currency = value.currency;
    _currencySymbol = value.currencySymbol;
    _dateFormat = value.dateFormat;
    _timeFormat = value.timeFormat;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsLoaded &&
              state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsInitial ||
              state is SettingsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is SettingsFailure) {
            return Center(child: Text(state.message));
          }

          final loaded = state as SettingsLoaded;
          _fill(loaded.settings);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _section(
                  context,
                  title: 'School Profile',
                  children: [
                    _field(
                      _schoolName,
                      'School Name',
                      required: true,
                    ),
                    _field(
                      _schoolCode,
                      'School Code',
                      required: true,
                    ),
                    _field(_tagLine, 'Tag Line'),
                    _field(_address, 'Address'),
                    _field(_city, 'City'),
                    _field(_country, 'Country'),
                    _field(_phone, 'Phone'),
                    _field(_whatsApp, 'WhatsApp'),
                    _field(_email, 'Email'),
                    _field(_website, 'Website'),
                  ],
                ),
                const SizedBox(height: 14),
                _section(
                  context,
                  title: 'Academic Settings',
                  children: [
                    _field(
                      _session,
                      'Current Session',
                      required: true,
                    ),
                    _dateTile(
                      context,
                      'Session Start Date',
                      _sessionStart,
                      (value) {
                        setState(() => _sessionStart = value);
                      },
                    ),
                    _dateTile(
                      context,
                      'Session End Date',
                      _sessionEnd,
                      (value) {
                        setState(() => _sessionEnd = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _section(
                  context,
                  title: 'Regional Settings',
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'PKR',
                          child: Text('PKR'),
                        ),
                        DropdownMenuItem(
                          value: 'USD',
                          child: Text('USD'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _currency = value);
                        }
                      },
                    ),
                    _field(
                      null,
                      'Currency Symbol',
                      externalValue: _currencySymbol,
                      onChanged: (value) {
                        _currencySymbol = value;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _dateFormat,
                      decoration: const InputDecoration(
                        labelText: 'Date Format',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'dd-MM-yyyy',
                          child: Text('dd-MM-yyyy'),
                        ),
                        DropdownMenuItem(
                          value: 'dd/MM/yyyy',
                          child: Text('dd/MM/yyyy'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _dateFormat = value);
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _timeFormat,
                      decoration: const InputDecoration(
                        labelText: 'Time Format',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '12 Hour',
                          child: Text('12 Hour'),
                        ),
                        DropdownMenuItem(
                          value: '24 Hour',
                          child: Text('24 Hour'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _timeFormat = value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _section(
                  context,
                  title: 'System Prefixes',
                  children: [
                    _field(
                      _admissionPrefix,
                      'Admission Prefix',
                    ),
                    _field(
                      _rollPrefix,
                      'Roll Number Prefix',
                    ),
                    _field(
                      _receiptPrefix,
                      'Receipt Prefix',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _section(
                  context,
                  title: 'Branding',
                  children: [
                    _field(_logoUrl, 'School Logo URL'),
                    _field(
                      _headerUrl,
                      'Report Header URL',
                    ),
                    _field(
                      _footerUrl,
                      'Report Footer URL',
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
                              loaded.settings.id,
                            ),
                    icon: loaded.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Settings'),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 800
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: children
                      .map(
                        (child) => SizedBox(
                          width: width,
                          child: child,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController? controller,
    String label, {
    bool required = false,
    String? externalValue,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      initialValue:
          controller == null ? externalValue : null,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required.';
              }
              return null;
            }
          : null,
    );
  }

  Widget _dateTile(
    BuildContext context,
    String label,
    DateTime value,
    ValueChanged<DateTime> onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year}',
      ),
      trailing: const Icon(Icons.calendar_month_outlined),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          onChanged(picked);
        }
      },
    );
  }

  void _save(BuildContext context, String id) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<SettingsBloc>().add(
          SaveSettingsRequested(
            SchoolSettingsEntity(
              id: id,
              schoolName: _schoolName.text.trim(),
              schoolCode: _schoolCode.text.trim(),
              currentSession: _session.text.trim(),
              sessionStartDate: _sessionStart,
              sessionEndDate: _sessionEnd,
              currency: _currency,
              currencySymbol: _currencySymbol.trim(),
              dateFormat: _dateFormat,
              timeFormat: _timeFormat,
              admissionPrefix:
                  _admissionPrefix.text.trim(),
              rollNumberPrefix:
                  _rollPrefix.text.trim(),
              receiptPrefix:
                  _receiptPrefix.text.trim(),
              updatedAt: DateTime.now(),
              tagLine: _tagLine.text.trim(),
              address: _address.text.trim(),
              city: _city.text.trim(),
              country: _country.text.trim(),
              phone: _phone.text.trim(),
              whatsApp: _whatsApp.text.trim(),
              email: _email.text.trim(),
              website: _website.text.trim(),
              logoUrl: _logoUrl.text.trim(),
              reportHeaderUrl: _headerUrl.text.trim(),
              reportFooterUrl: _footerUrl.text.trim(),
            ),
          ),
        );
  }
}
'@

$pathsFile = 'lib/core/constants/firestore_paths.dart'
$pathsText = ReadUtf8 $pathsFile

if (-not $pathsText.Contains(
  'static const String systemSettings'
)) {
  $anchor = "  static const String students = 'students';"

  if (-not $pathsText.Contains($anchor)) {
    throw 'FIRESTORE PATH ANCHOR ERROR.'
  }

  $replacement = @"
  static const String systemSettings = 'system_settings';
  static const String backupHistory = 'backup_history';
$anchor
"@

  BackupFile $pathsFile
  WriteUtf8 $pathsFile (
    $pathsText.Replace($anchor,$replacement)
  )
}

$slFile = 'lib/core/di/service_locator.dart'
$slText = ReadUtf8 $slFile

$imports = @"
import '../../features/settings/data/datasources/settings_remote_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/manage_settings.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
"@

if (-not $slText.Contains(
  'settings_remote_datasource.dart'
)) {
  InsertBefore `
    $slFile `
    "import '../../features/students/data/datasources/student_remote_datasource.dart';" `
    $imports
}

$registrations = @"
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      sl<SettingsRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetSchoolSettings>(
    () => GetSchoolSettings(
      sl<SettingsRepository>(),
    ),
  );
  sl.registerLazySingleton<SaveSchoolSettings>(
    () => SaveSchoolSettings(
      sl<SettingsRepository>(),
    ),
  );
  sl.registerFactory<SettingsBloc>(
    () => SettingsBloc(
      getSettings: sl<GetSchoolSettings>(),
      saveSettings: sl<SaveSchoolSettings>(),
    ),
  );

"@

if (-not $slText.Contains(
  'sl.registerLazySingleton<SettingsRepository>'
)) {
  InsertBefore `
    $slFile `
    '  sl.registerLazySingleton<StudentRemoteDataSource>(' `
    $registrations
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
Write-Host 'Settings Phase 1 Foundation installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Entry page: SettingsDashboardPage' -ForegroundColor Yellow
