[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\communication_phase2_$stamp"

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

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  Fail 'PROJECT ROOT ERROR: Run from Flutter project root.'
}

$required = @(
  'lib/features/communication/domain/entities/communication_message_entity.dart',
  'lib/features/communication/domain/repositories/communication_repository.dart',
  'lib/features/communication/data/datasources/communication_remote_datasource.dart',
  'lib/features/communication/data/repositories/communication_repository_impl.dart',
  'lib/features/communication/presentation/bloc/communication_bloc.dart',
  'lib/features/communication/presentation/bloc/communication_event.dart',
  'lib/features/communication/presentation/bloc/communication_state.dart',
  'lib/features/communication/presentation/pages/communication_dashboard_page.dart'
)

foreach ($path in $required) {
  if (-not (Test-Path (Full $path))) {
    Fail "REQUIRED FILE ERROR: $path"
  }
}

if (Test-Path (Full 'lib/features/communication/presentation/pages/announcements_page.dart')) {
  Fail 'EXISTING FILE ERROR: Communication Phase 2 appears already installed.'
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($path in $required) { BackupFile $path }

WriteUtf8 'lib/features/communication/domain/repositories/communication_repository.dart' @'
import '../entities/communication_message_entity.dart';

abstract class CommunicationRepository {
  Future<List<CommunicationMessageEntity>> getMessages();
  Future<void> saveMessage(CommunicationMessageEntity message);
  Future<void> deleteMessage(String messageId);
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
  Future<void> deleteMessage(String messageId);
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

    values.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });

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

  @override
  Future<void> deleteMessage(String messageId) {
    return _service
        .collection(FirestorePaths.communicationMessages)
        .doc(messageId)
        .delete();
  }
}
'@

WriteUtf8 'lib/features/communication/data/repositories/communication_repository_impl.dart' @'
import '../../domain/entities/communication_message_entity.dart';
import '../../domain/repositories/communication_repository.dart';
import '../datasources/communication_remote_datasource.dart';

class CommunicationRepositoryImpl
    implements CommunicationRepository {
  CommunicationRepositoryImpl(this._source);

  final CommunicationRemoteDataSource _source;

  @override
  Future<List<CommunicationMessageEntity>> getMessages() {
    return _source.getMessages();
  }

  @override
  Future<void> saveMessage(
    CommunicationMessageEntity message,
  ) {
    return _source.saveMessage(message);
  }

  @override
  Future<void> deleteMessage(String messageId) {
    return _source.deleteMessage(messageId);
  }
}
'@

WriteUtf8 'lib/features/communication/domain/usecases/delete_communication_message.dart' @'
import '../repositories/communication_repository.dart';

class DeleteCommunicationMessage {
  const DeleteCommunicationMessage(this._repository);

  final CommunicationRepository _repository;

  Future<void> call(String messageId) {
    if (messageId.trim().isEmpty) {
      throw ArgumentError('Message ID is required.');
    }
    return _repository.deleteMessage(messageId);
  }
}
'@

WriteUtf8 'lib/features/communication/presentation/bloc/communication_event.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/communication_message_entity.dart';

sealed class CommunicationEvent extends Equatable {
  const CommunicationEvent();

  @override
  List<Object?> get props => const [];
}

class LoadCommunicationDashboard extends CommunicationEvent {
  const LoadCommunicationDashboard();
}

class SaveCommunicationMessageRequested
    extends CommunicationEvent {
  const SaveCommunicationMessageRequested(this.message);

  final CommunicationMessageEntity message;

  @override
  List<Object?> get props => [message];
}

class DeleteCommunicationMessageRequested
    extends CommunicationEvent {
  const DeleteCommunicationMessageRequested(this.messageId);

  final String messageId;

  @override
  List<Object?> get props => [messageId];
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
  const CommunicationLoaded({
    required this.messages,
    this.isProcessing = false,
    this.message,
    this.error,
  });

  final List<CommunicationMessageEntity> messages;
  final bool isProcessing;
  final String? message;
  final String? error;

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

  CommunicationLoaded copyWith({
    List<CommunicationMessageEntity>? messages,
    bool? isProcessing,
    String? message,
    String? error,
    bool clearMessages = false,
  }) {
    return CommunicationLoaded(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      message: clearMessages ? null : message ?? this.message,
      error: clearMessages ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        isProcessing,
        message,
        error,
      ];
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

import '../../domain/usecases/delete_communication_message.dart';
import '../../domain/usecases/get_communication_messages.dart';
import '../../domain/usecases/save_communication_message.dart';
import 'communication_event.dart';
import 'communication_state.dart';

class CommunicationBloc
    extends Bloc<CommunicationEvent, CommunicationState> {
  CommunicationBloc({
    required GetCommunicationMessages getMessages,
    required SaveCommunicationMessage saveMessage,
    required DeleteCommunicationMessage deleteMessage,
  })  : _getMessages = getMessages,
        _saveMessage = saveMessage,
        _deleteMessage = deleteMessage,
        super(const CommunicationInitial()) {
    on<LoadCommunicationDashboard>(_load);
    on<SaveCommunicationMessageRequested>(_save);
    on<DeleteCommunicationMessageRequested>(_delete);
  }

  final GetCommunicationMessages _getMessages;
  final SaveCommunicationMessage _saveMessage;
  final DeleteCommunicationMessage _deleteMessage;

  Future<void> _load(
    LoadCommunicationDashboard event,
    Emitter<CommunicationState> emit,
  ) async {
    emit(const CommunicationLoading());
    await _reload(emit);
  }

  Future<void> _save(
    SaveCommunicationMessageRequested event,
    Emitter<CommunicationState> emit,
  ) async {
    final current = state;
    if (current is CommunicationLoaded) {
      emit(
        current.copyWith(
          isProcessing: true,
          clearMessages: true,
        ),
      );
    }

    try {
      await _saveMessage(event.message);
      await _reload(
        emit,
        message: 'Announcement saved successfully.',
      );
    } catch (error) {
      if (current is CommunicationLoaded) {
        emit(
          current.copyWith(
            isProcessing: false,
            error: _message(error),
            clearMessages: true,
          ),
        );
      } else {
        emit(CommunicationFailure(_message(error)));
      }
    }
  }

  Future<void> _delete(
    DeleteCommunicationMessageRequested event,
    Emitter<CommunicationState> emit,
  ) async {
    final current = state;
    if (current is CommunicationLoaded) {
      emit(
        current.copyWith(
          isProcessing: true,
          clearMessages: true,
        ),
      );
    }

    try {
      await _deleteMessage(event.messageId);
      await _reload(
        emit,
        message: 'Announcement deleted successfully.',
      );
    } catch (error) {
      if (current is CommunicationLoaded) {
        emit(
          current.copyWith(
            isProcessing: false,
            error: _message(error),
            clearMessages: true,
          ),
        );
      } else {
        emit(CommunicationFailure(_message(error)));
      }
    }
  }

  Future<void> _reload(
    Emitter<CommunicationState> emit, {
    String? message,
  }) async {
    try {
      emit(
        CommunicationLoaded(
          messages: await _getMessages(),
          message: message,
        ),
      );
    } catch (error) {
      emit(CommunicationFailure(_message(error)));
    }
  }

  String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
'@

WriteUtf8 'lib/features/communication/presentation/pages/announcements_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/communication_message_entity.dart';
import '../bloc/communication_bloc.dart';
import '../bloc/communication_event.dart';
import '../bloc/communication_state.dart';

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CommunicationBloc>()
        ..add(const LoadCommunicationDashboard()),
      child: const _AnnouncementsView(),
    );
  }
}

class _AnnouncementsView extends StatefulWidget {
  const _AnnouncementsView();

  @override
  State<_AnnouncementsView> createState() =>
      _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<_AnnouncementsView> {
  CommunicationMessageStatus? _statusFilter;
  CommunicationAudienceType? _audienceFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements & Circulars'),
        actions: const [DashboardNavigationButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('New Announcement'),
      ),
      body: BlocConsumer<CommunicationBloc, CommunicationState>(
        listener: (context, state) {
          if (state is! CommunicationLoaded) return;
          final text = state.error ?? state.message;
          if (text == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
        },
        builder: (context, state) {
          if (state is CommunicationInitial ||
              state is CommunicationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CommunicationFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as CommunicationLoaded;
          final messages = data.messages.where((message) {
            final statusMatches =
                _statusFilter == null ||
                message.status == _statusFilter;
            final audienceMatches =
                _audienceFilter == null ||
                message.audienceType == _audienceFilter;
            return statusMatches && audienceMatches;
          }).toList();

          return Column(
            children: [
              if (data.isProcessing)
                const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 210,
                      child: DropdownButtonFormField<
                          CommunicationMessageStatus?>(
                        initialValue: _statusFilter,
                        decoration:
                            const InputDecoration(labelText: 'Status'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Statuses'),
                          ),
                          ...CommunicationMessageStatus.values.map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(_label(item.name)),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _statusFilter = value),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<
                          CommunicationAudienceType?>(
                        initialValue: _audienceFilter,
                        decoration:
                            const InputDecoration(labelText: 'Audience'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Audiences'),
                          ),
                          ...CommunicationAudienceType.values.map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(_label(item.name)),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _audienceFilter = value),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: messages.isEmpty
                    ? const Center(
                        child: Text('No announcements found.'),
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: messages.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(
                                  message.isPinned
                                      ? Icons.push_pin
                                      : Icons.campaign_outlined,
                                ),
                              ),
                              title: Text(message.title),
                              subtitle: Text(
                                '${_label(message.audienceType.name)} • '
                                '${_label(message.status.name)}'
                                '${message.isExpired ? ' • Expired' : ''}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditor(
                                      context,
                                      existing: message,
                                    );
                                  } else if (value == 'delete') {
                                    _delete(context, message);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context, {
    CommunicationMessageEntity? existing,
  }) async {
    final titleController =
        TextEditingController(text: existing?.title ?? '');
    final bodyController =
        TextEditingController(text: existing?.body ?? '');
    final attachmentController = TextEditingController(
      text: existing?.attachmentUrl ?? '',
    );
    final targetsController = TextEditingController(
      text: existing?.targetIds.join(', ') ?? '',
    );

    var audience =
        existing?.audienceType ??
        CommunicationAudienceType.wholeSchool;
    var status =
        existing?.status ??
        CommunicationMessageStatus.draft;
    var isPinned = existing?.isPinned ?? false;
    var inApp =
        existing?.channels.contains(CommunicationChannel.inApp) ??
        true;
    var push = existing?.channels.contains(
          CommunicationChannel.pushNotification,
        ) ??
        false;
    var whatsapp =
        existing?.channels.contains(
          CommunicationChannel.whatsapp,
        ) ??
        false;
    DateTime? scheduledAt = existing?.scheduledAt;
    DateTime? expiresAt = existing?.expiresAt;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null
                ? 'New Announcement'
                : 'Edit Announcement',
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration:
                        const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    maxLines: 5,
                    decoration:
                        const InputDecoration(labelText: 'Message'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<
                      CommunicationAudienceType>(
                    initialValue: audience,
                    decoration:
                        const InputDecoration(labelText: 'Audience'),
                    items: CommunicationAudienceType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_label(item.name)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => audience = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetsController,
                    decoration: const InputDecoration(
                      labelText:
                          'Target IDs (comma separated, optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<
                      CommunicationMessageStatus>(
                    initialValue: status,
                    decoration:
                        const InputDecoration(labelText: 'Status'),
                    items: CommunicationMessageStatus.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_label(item.name)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isPinned,
                    title: const Text('Pin announcement'),
                    onChanged: (value) {
                      setDialogState(
                        () => isPinned = value ?? false,
                      );
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: inApp,
                    title: const Text('In-App'),
                    onChanged: (value) {
                      setDialogState(
                        () => inApp = value ?? false,
                      );
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: push,
                    title: const Text('Push Notification'),
                    onChanged: (value) {
                      setDialogState(
                        () => push = value ?? false,
                      );
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: whatsapp,
                    title: const Text('WhatsApp'),
                    onChanged: (value) {
                      setDialogState(
                        () => whatsapp = value ?? false,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: attachmentController,
                    decoration: const InputDecoration(
                      labelText: 'Attachment URL (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Schedule Date'),
                    subtitle: Text(
                      scheduledAt == null
                          ? 'Not scheduled'
                          : _date(scheduledAt!),
                    ),
                    trailing:
                        const Icon(Icons.schedule_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate:
                            scheduledAt ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(
                          () => scheduledAt = picked,
                        );
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Expiry Date'),
                    subtitle: Text(
                      expiresAt == null
                          ? 'No expiry'
                          : _date(expiresAt!),
                    ),
                    trailing:
                        const Icon(Icons.event_busy_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate:
                            expiresAt ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(
                          () => expiresAt = picked,
                        );
                      }
                    },
                  ),
                ],
              ),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (save == true && context.mounted) {
      final channels = <CommunicationChannel>[
        if (inApp) CommunicationChannel.inApp,
        if (push) CommunicationChannel.pushNotification,
        if (whatsapp) CommunicationChannel.whatsapp,
      ];
      final now = DateTime.now();
      final user = sl<GetCurrentUserUseCase>()();

      context.read<CommunicationBloc>().add(
            SaveCommunicationMessageRequested(
              CommunicationMessageEntity(
                id: existing?.id ??
                    'communication_${now.microsecondsSinceEpoch}',
                title: titleController.text.trim(),
                body: bodyController.text.trim(),
                channels: channels,
                audienceType: audience,
                targetIds: targetsController.text
                    .split(',')
                    .map((item) => item.trim())
                    .where((item) => item.isNotEmpty)
                    .toList(),
                status: status,
                isPinned: isPinned,
                createdBy:
                    existing?.createdBy ?? user?.uid ?? '',
                createdAt: existing?.createdAt ?? now,
                updatedAt: now,
                scheduledAt: status ==
                        CommunicationMessageStatus.scheduled
                    ? scheduledAt
                    : null,
                publishedAt: status ==
                        CommunicationMessageStatus.published
                    ? existing?.publishedAt ?? now
                    : null,
                expiresAt: expiresAt,
                attachmentUrl:
                    attachmentController.text.trim(),
              ),
            ),
          );
    }

    titleController.dispose();
    bodyController.dispose();
    attachmentController.dispose();
    targetsController.dispose();
  }

  Future<void> _delete(
    BuildContext context,
    CommunicationMessageEntity message,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text(
          'Delete "${message.title}" permanently?',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CommunicationBloc>().add(
            DeleteCommunicationMessageRequested(message.id),
          );
    }
  }

  static String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year}';
  }

  static String _label(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
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
import 'announcements_page.dart';

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
            return const Center(
              child: CircularProgressIndicator(),
            );
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
              _ModuleCard(
                title: 'Announcements & Circulars',
                subtitle: 'Create, schedule, publish, and archive',
                icon: Icons.campaign_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const AnnouncementsPage(),
                    ),
                  );
                },
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
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
'@

$slFile = 'lib/core/di/service_locator.dart'
$slText = ReadUtf8 $slFile

if (-not $slText.Contains(
  "import '../../features/communication/domain/usecases/delete_communication_message.dart';"
)) {
  $importAnchor = "import '../../features/communication/domain/usecases/get_communication_messages.dart';"
  $importReplacement = @"
import '../../features/communication/domain/usecases/delete_communication_message.dart';
$importAnchor
"@
  $index = $slText.IndexOf($importAnchor,[StringComparison]::Ordinal)
  if ($index -lt 0) { Fail 'ANCHOR ERROR: Communication use-case import anchor missing.' }
  BackupFile $slFile
  $slText = $slText.Substring(0,$index) + $importReplacement +
      $slText.Substring($index + $importAnchor.Length)
  WriteUtf8 $slFile $slText
}

$slText = ReadUtf8 $slFile

if (-not $slText.Contains('sl.registerLazySingleton<DeleteCommunicationMessage>')) {
  $useCaseAnchor = '  sl.registerLazySingleton<GetCommunicationMessages>('
  $useCaseReplacement = @"
  sl.registerLazySingleton<DeleteCommunicationMessage>(
    () => DeleteCommunicationMessage(sl<CommunicationRepository>()),
  );

$useCaseAnchor
"@
  $index = $slText.IndexOf($useCaseAnchor,[StringComparison]::Ordinal)
  if ($index -lt 0) { Fail 'ANCHOR ERROR: Communication use-case registration anchor missing.' }
  BackupFile $slFile
  $slText = $slText.Substring(0,$index) + $useCaseReplacement +
      $slText.Substring($index + $useCaseAnchor.Length)
  WriteUtf8 $slFile $slText
}

$slText = ReadUtf8 $slFile
$oldBlocRegistration = @"
  sl.registerFactory<CommunicationBloc>(
    () => CommunicationBloc(sl<GetCommunicationMessages>()),
  );
"@
$newBlocRegistration = @"
  sl.registerFactory<CommunicationBloc>(
    () => CommunicationBloc(
      getMessages: sl<GetCommunicationMessages>(),
      saveMessage: sl<SaveCommunicationMessage>(),
      deleteMessage: sl<DeleteCommunicationMessage>(),
    ),
  );
"@

if ($slText.Contains($oldBlocRegistration)) {
  BackupFile $slFile
  WriteUtf8 $slFile ($slText.Replace(
    $oldBlocRegistration,
    $newBlocRegistration
  ))
} elseif (-not $slText.Contains('deleteMessage: sl<DeleteCommunicationMessage>()')) {
  Fail 'ANCHOR ERROR: CommunicationBloc registration could not be updated.'
}

& dart format lib/features/communication lib/core/di/service_locator.dart
if ($LASTEXITCODE -ne 0) {
  Fail "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze lib/features/communication --no-fatal-infos --no-fatal-warnings
if ($LASTEXITCODE -ne 0) {
  Fail "COMMUNICATION ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Communication Phase 2 Announcements installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
