[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\communication_phase1_$stamp"

function Full([string]$Path) { Join-Path $root $Path }
function Fail([string]$Message) { throw $Message }
function ReadUtf8([string]$Path) { [IO.File]::ReadAllText((Full $Path)) }
function WriteUtf8([string]$Path,[string]$Text) {
  $full = Full $Path
  $dir = Split-Path $full -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  [IO.File]::WriteAllText($full,$Text.Replace("`r`n","`n"),$utf8)
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
function ReplaceOnce([string]$Path,[string]$Anchor,[string]$Replacement) {
  $text = ReadUtf8 $Path
  $index = $text.IndexOf($Anchor,[StringComparison]::Ordinal)
  if ($index -lt 0) {
    Fail "ANCHOR ERROR: Anchor not found in $Path.`n$Anchor"
  }
  BackupFile $Path
  WriteUtf8 $Path (
    $text.Substring(0,$index) +
    $Replacement +
    $text.Substring($index + $Anchor.Length)
  )
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  Fail 'PROJECT ROOT ERROR: Run from Flutter project root.'
}

foreach ($path in @(
  'lib/core/constants/firestore_paths.dart',
  'lib/core/di/service_locator.dart',
  'lib/core/services/firebase_firestore_service.dart'
)) {
  if (-not (Test-Path (Full $path))) {
    Fail "REQUIRED FILE ERROR: $path"
  }
}

if (Test-Path (Full 'lib/features/communication')) {
  Fail 'EXISTING MODULE ERROR: lib/features/communication already exists.'
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
BackupFile 'lib/core/constants/firestore_paths.dart'
BackupFile 'lib/core/di/service_locator.dart'

WriteUtf8 'lib/features/communication/domain/entities/communication_message_entity.dart' @'
import 'package:equatable/equatable.dart';

enum CommunicationChannel { inApp, pushNotification, whatsapp }

enum CommunicationAudienceType {
  wholeSchool,
  teachers,
  parents,
  students,
  staff,
  classSection,
  selectedUsers,
}

enum CommunicationMessageStatus { draft, scheduled, published, archived }

class CommunicationMessageEntity extends Equatable {
  const CommunicationMessageEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.channels,
    required this.audienceType,
    required this.targetIds,
    required this.status,
    required this.isPinned,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledAt,
    this.publishedAt,
    this.expiresAt,
    this.attachmentUrl = '',
  });

  final String id;
  final String title;
  final String body;
  final List<CommunicationChannel> channels;
  final CommunicationAudienceType audienceType;
  final List<String> targetIds;
  final CommunicationMessageStatus status;
  final bool isPinned;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final String attachmentUrl;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        channels,
        audienceType,
        targetIds,
        status,
        isPinned,
        createdBy,
        createdAt,
        updatedAt,
        scheduledAt,
        publishedAt,
        expiresAt,
        attachmentUrl,
      ];
}
'@

WriteUtf8 'lib/features/communication/data/models/communication_message_model.dart' @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/communication_message_entity.dart';

class CommunicationMessageModel extends CommunicationMessageEntity {
  const CommunicationMessageModel({
    required super.id,
    required super.title,
    required super.body,
    required super.channels,
    required super.audienceType,
    required super.targetIds,
    required super.status,
    required super.isPinned,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.scheduledAt,
    super.publishedAt,
    super.expiresAt,
    super.attachmentUrl,
  });

  factory CommunicationMessageModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    DateTime? nullableDate(dynamic value) =>
        value == null ? null : date(value);

    return CommunicationMessageModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      channels: ((map['channels'] as List?) ?? const [])
          .map(
            (value) => CommunicationChannel.values.firstWhere(
              (item) => item.name == value,
              orElse: () => CommunicationChannel.inApp,
            ),
          )
          .toList(),
      audienceType: CommunicationAudienceType.values.firstWhere(
        (item) => item.name == map['audienceType'],
        orElse: () => CommunicationAudienceType.wholeSchool,
      ),
      targetIds: List<String>.from(
        (map['targetIds'] as List?) ?? const [],
      ),
      status: CommunicationMessageStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => CommunicationMessageStatus.draft,
      ),
      isPinned: map['isPinned'] as bool? ?? false,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
      scheduledAt: nullableDate(map['scheduledAt']),
      publishedAt: nullableDate(map['publishedAt']),
      expiresAt: nullableDate(map['expiresAt']),
      attachmentUrl: map['attachmentUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'channels': channels.map((item) => item.name).toList(),
        'audienceType': audienceType.name,
        'targetIds': targetIds,
        'status': status.name,
        'isPinned': isPinned,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'scheduledAt': scheduledAt?.toIso8601String(),
        'publishedAt': publishedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'attachmentUrl': attachmentUrl,
        'schemaVersion': 1,
      };
}
'@

WriteUtf8 'lib/features/communication/domain/repositories/communication_repository.dart' @'
import '../entities/communication_message_entity.dart';

abstract class CommunicationRepository {
  Future<List<CommunicationMessageEntity>> getMessages();
  Future<void> saveMessage(CommunicationMessageEntity message);
}
'@

WriteUtf8 'lib/features/communication/data/datasources/communication_remote_datasource.dart' @'
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/communication_message_entity.dart';
import '../models/communication_message_model.dart';

abstract class CommunicationRemoteDataSource {
  Future<List<CommunicationMessageEntity>> getMessages();
  Future<void> saveMessage(CommunicationMessageEntity message);
}

class CommunicationRemoteDataSourceImpl
    implements CommunicationRemoteDataSource {
  CommunicationRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<CommunicationMessageEntity>> getMessages() async {
    final snapshot = await _service
        .collection(FirestorePaths.communicationMessages)
        .get();
    final values = snapshot.docs
        .map(
          (doc) => CommunicationMessageModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();
    values.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  @override
  Future<void> saveMessage(CommunicationMessageEntity message) {
    final model = CommunicationMessageModel(
      id: message.id,
      title: message.title,
      body: message.body,
      channels: message.channels,
      audienceType: message.audienceType,
      targetIds: message.targetIds,
      status: message.status,
      isPinned: message.isPinned,
      createdBy: message.createdBy,
      createdAt: message.createdAt,
      updatedAt: message.updatedAt,
      scheduledAt: message.scheduledAt,
      publishedAt: message.publishedAt,
      expiresAt: message.expiresAt,
      attachmentUrl: message.attachmentUrl,
    );
    return _service
        .collection(FirestorePaths.communicationMessages)
        .doc(message.id)
        .set(model.toMap());
  }
}
'@

WriteUtf8 'lib/features/communication/data/repositories/communication_repository_impl.dart' @'
import '../../domain/entities/communication_message_entity.dart';
import '../../domain/repositories/communication_repository.dart';
import '../datasources/communication_remote_datasource.dart';

class CommunicationRepositoryImpl implements CommunicationRepository {
  CommunicationRepositoryImpl(this._source);

  final CommunicationRemoteDataSource _source;

  @override
  Future<List<CommunicationMessageEntity>> getMessages() =>
      _source.getMessages();

  @override
  Future<void> saveMessage(CommunicationMessageEntity message) =>
      _source.saveMessage(message);
}
'@

WriteUtf8 'lib/features/communication/domain/usecases/get_communication_messages.dart' @'
import '../entities/communication_message_entity.dart';
import '../repositories/communication_repository.dart';

class GetCommunicationMessages {
  const GetCommunicationMessages(this._repository);

  final CommunicationRepository _repository;

  Future<List<CommunicationMessageEntity>> call() =>
      _repository.getMessages();
}
'@

WriteUtf8 'lib/features/communication/domain/usecases/save_communication_message.dart' @'
import '../entities/communication_message_entity.dart';
import '../repositories/communication_repository.dart';

class SaveCommunicationMessage {
  const SaveCommunicationMessage(this._repository);

  final CommunicationRepository _repository;

  Future<void> call(CommunicationMessageEntity message) {
    if (message.title.trim().isEmpty) {
      throw ArgumentError('Message title is required.');
    }
    if (message.body.trim().isEmpty) {
      throw ArgumentError('Message body is required.');
    }
    if (message.channels.isEmpty) {
      throw ArgumentError('Select at least one channel.');
    }
    return _repository.saveMessage(message);
  }
}
'@

WriteUtf8 'lib/features/communication/presentation/bloc/communication_event.dart' @'
import 'package:equatable/equatable.dart';

sealed class CommunicationEvent extends Equatable {
  const CommunicationEvent();

  @override
  List<Object?> get props => const [];
}

class LoadCommunicationDashboard extends CommunicationEvent {
  const LoadCommunicationDashboard();
}
'@

WriteUtf8 'lib/features/communication/presentation/bloc/communication_state.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/communication_message_entity.dart';

sealed class CommunicationState extends Equatable {
  const CommunicationState();

  @override
  List<Object?> get props => const [];
}

class CommunicationInitial extends CommunicationState {
  const CommunicationInitial();
}

class CommunicationLoading extends CommunicationState {
  const CommunicationLoading();
}

class CommunicationLoaded extends CommunicationState {
  const CommunicationLoaded(this.messages);

  final List<CommunicationMessageEntity> messages;

  int get publishedCount => messages
      .where(
        (item) =>
            item.status == CommunicationMessageStatus.published,
      )
      .length;

  int get scheduledCount => messages
      .where(
        (item) =>
            item.status == CommunicationMessageStatus.scheduled,
      )
      .length;

  @override
  List<Object?> get props => [messages];
}

class CommunicationFailure extends CommunicationState {
  const CommunicationFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
'@

WriteUtf8 'lib/features/communication/presentation/bloc/communication_bloc.dart' @'
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_communication_messages.dart';
import 'communication_event.dart';
import 'communication_state.dart';

class CommunicationBloc
    extends Bloc<CommunicationEvent, CommunicationState> {
  CommunicationBloc(this._getMessages)
      : super(const CommunicationInitial()) {
    on<LoadCommunicationDashboard>(_load);
  }

  final GetCommunicationMessages _getMessages;

  Future<void> _load(
    LoadCommunicationDashboard event,
    Emitter<CommunicationState> emit,
  ) async {
    emit(const CommunicationLoading());
    try {
      emit(CommunicationLoaded(await _getMessages()));
    } catch (error) {
      emit(
        CommunicationFailure(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
'@

WriteUtf8 'lib/features/communication/presentation/pages/communication_dashboard_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../bloc/communication_bloc.dart';
import '../bloc/communication_event.dart';
import '../bloc/communication_state.dart';

class CommunicationDashboardPage extends StatelessWidget {
  const CommunicationDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CommunicationBloc>()
        ..add(const LoadCommunicationDashboard()),
      child: const _CommunicationDashboardView(),
    );
  }
}

class _CommunicationDashboardView extends StatelessWidget {
  const _CommunicationDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocBuilder<CommunicationBloc, CommunicationState>(
        builder: (context, state) {
          if (state is CommunicationInitial ||
              state is CommunicationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CommunicationFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as CommunicationLoaded;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    title: 'Total Messages',
                    value: data.messages.length,
                    icon: Icons.forum_outlined,
                  ),
                  _SummaryCard(
                    title: 'Published',
                    value: data.publishedCount,
                    icon: Icons.campaign_outlined,
                  ),
                  _SummaryCard(
                    title: 'Scheduled',
                    value: data.scheduledCount,
                    icon: Icons.schedule_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _ModuleCard(
                title: 'Announcements & Circulars',
                subtitle: 'Phase 2',
                icon: Icons.campaign_outlined,
              ),
              const _ModuleCard(
                title: 'Push Notifications',
                subtitle: 'Phase 3',
                icon: Icons.notifications_active_outlined,
              ),
              const _ModuleCard(
                title: 'WhatsApp Integration',
                subtitle: 'Phase 4',
                icon: Icons.chat_outlined,
              ),
              const _ModuleCard(
                title: 'In-App Chat',
                subtitle: 'Phase 5',
                icon: Icons.forum_outlined,
              ),
              const _ModuleCard(
                title: 'Broadcast Messages',
                subtitle: 'Phase 6',
                icon: Icons.cell_tower_outlined,
              ),
              const _ModuleCard(
                title: 'Communication History',
                subtitle: 'Phase 7',
                icon: Icons.history_outlined,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    '$value',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
'@

$pathsFile = 'lib/core/constants/firestore_paths.dart'
$pathsAnchor = "  static const String notices = 'notices';"
$pathsReplacement = @"
  static const String communicationMessages = 'communication_messages';
  static const String communicationReceipts = 'communication_receipts';
  static const String communicationThreads = 'communication_threads';
  static const String communicationParticipants =
      'communication_participants';
  static const String communicationDeliveryLogs =
      'communication_delivery_logs';
$pathsAnchor
"@
ReplaceOnce $pathsFile $pathsAnchor $pathsReplacement

$slFile = 'lib/core/di/service_locator.dart'

$importAnchor = "import '../../features/attendance/data/datasources/attendance_remote_datasource.dart';"
$importReplacement = @"
import '../../features/communication/data/datasources/communication_remote_datasource.dart';
import '../../features/communication/data/repositories/communication_repository_impl.dart';
import '../../features/communication/domain/repositories/communication_repository.dart';
import '../../features/communication/domain/usecases/get_communication_messages.dart';
import '../../features/communication/domain/usecases/save_communication_message.dart';
import '../../features/communication/presentation/bloc/communication_bloc.dart';
$importAnchor
"@
ReplaceOnce $slFile $importAnchor $importReplacement

$repoAnchor = '  sl.registerLazySingleton<AcademicStructureRepository>('
$repoReplacement = @"
  sl.registerLazySingleton<CommunicationRemoteDataSource>(
    () => CommunicationRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<CommunicationRepository>(
    () => CommunicationRepositoryImpl(
      sl<CommunicationRemoteDataSource>(),
    ),
  );

$repoAnchor
"@
ReplaceOnce $slFile $repoAnchor $repoReplacement

$useCaseAnchor = '  sl.registerLazySingleton<LoginUseCase>('
$useCaseReplacement = @"
  sl.registerLazySingleton<GetCommunicationMessages>(
    () => GetCommunicationMessages(sl<CommunicationRepository>()),
  );
  sl.registerLazySingleton<SaveCommunicationMessage>(
    () => SaveCommunicationMessage(sl<CommunicationRepository>()),
  );

$useCaseAnchor
"@
ReplaceOnce $slFile $useCaseAnchor $useCaseReplacement

$blocAnchor = '  sl.registerFactory<AuthenticationBloc>('
$blocReplacement = @"
  sl.registerFactory<CommunicationBloc>(
    () => CommunicationBloc(sl<GetCommunicationMessages>()),
  );

$blocAnchor
"@
ReplaceOnce $slFile $blocAnchor $blocReplacement

& dart format lib/features/communication lib/core/constants/firestore_paths.dart lib/core/di/service_locator.dart
if ($LASTEXITCODE -ne 0) {
  Fail "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze lib/features/communication --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) {
  Fail "COMMUNICATION ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Communication Phase 1 Foundation installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
