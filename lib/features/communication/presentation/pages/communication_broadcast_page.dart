import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/communication_broadcast_entity.dart';
import '../../domain/entities/communication_message_entity.dart';
import '../bloc/communication_broadcast_bloc.dart';
import '../bloc/communication_broadcast_event.dart';
import '../bloc/communication_broadcast_state.dart';

class CommunicationBroadcastPage extends StatelessWidget {
  const CommunicationBroadcastPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CommunicationBroadcastBloc>()
            ..add(const LoadCommunicationBroadcasts()),
      child: const _CommunicationBroadcastView(),
    );
  }
}

class _CommunicationBroadcastView extends StatefulWidget {
  const _CommunicationBroadcastView();

  @override
  State<_CommunicationBroadcastView> createState() =>
      _CommunicationBroadcastViewState();
}

class _CommunicationBroadcastViewState
    extends State<_CommunicationBroadcastView> {
  CommunicationBroadcastStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Messaging'),
        actions: const [DashboardNavigationButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBroadcastDialog(context),
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('New Broadcast'),
      ),
      body: BlocConsumer<CommunicationBroadcastBloc, CommunicationBroadcastState>(
        listener: (context, state) {
          if (state is! CommunicationBroadcastLoaded) {
            return;
          }

          final text = state.error ?? state.message;
          if (text == null) return;

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
        },
        builder: (context, state) {
          if (state is CommunicationBroadcastInitial ||
              state is CommunicationBroadcastLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CommunicationBroadcastFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as CommunicationBroadcastLoaded;
          final items = data.broadcasts.where((item) {
            return _statusFilter == null || item.status == _statusFilter;
          }).toList();

          return Column(
            children: [
              if (data.isProcessing) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(label: Text('Total: ${data.broadcasts.length}')),
                    Chip(label: Text('Sent: ${data.sentCount}')),
                    Chip(label: Text('Failed: ${data.failedCount}')),
                    SizedBox(
                      width: 220,
                      child:
                          DropdownButtonFormField<
                            CommunicationBroadcastStatus?
                          >(
                            initialValue: _statusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Statuses'),
                              ),
                              ...CommunicationBroadcastStatus.values.map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(_label(item.name)),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _statusFilter = value);
                            },
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No broadcasts found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final canRetry =
                              item.status ==
                                  CommunicationBroadcastStatus.failed ||
                              item.status ==
                                  CommunicationBroadcastStatus.partiallyFailed;

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(
                                  canRetry
                                      ? Icons.error_outline
                                      : Icons.campaign_outlined,
                                ),
                              ),
                              title: Text(item.title),
                              subtitle: Text(
                                '${_label(item.audienceType.name)} | '
                                '${item.channels.map((e) => _label(e.name)).join(', ')} | '
                                '${_label(item.status.name)}',
                              ),
                              trailing: canRetry
                                  ? IconButton(
                                      tooltip: 'Retry',
                                      onPressed: data.isProcessing
                                          ? null
                                          : () {
                                              context
                                                  .read<
                                                    CommunicationBroadcastBloc
                                                  >()
                                                  .add(
                                                    RetryCommunicationBroadcastRequested(
                                                      item,
                                                    ),
                                                  );
                                            },
                                      icon: const Icon(Icons.refresh),
                                    )
                                  : Text(
                                      '${item.readCount}/'
                                      '${item.totalRecipients}',
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

  Future<void> _showBroadcastDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final targetsController = TextEditingController();
    final attachmentController = TextEditingController();

    var audience = CommunicationAudienceType.wholeSchool;
    var inApp = true;
    var push = true;
    var whatsapp = false;
    DateTime? scheduledAt;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Broadcast'),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Message'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CommunicationAudienceType>(
                    initialValue: audience,
                    decoration: const InputDecoration(labelText: 'Audience'),
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
                      labelText: 'Target IDs (comma separated)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: inApp,
                    title: const Text('In-App'),
                    onChanged: (value) {
                      setDialogState(() => inApp = value ?? false);
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: push,
                    title: const Text('Push Notification'),
                    onChanged: (value) {
                      setDialogState(() => push = value ?? false);
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: whatsapp,
                    title: const Text('WhatsApp'),
                    onChanged: (value) {
                      setDialogState(() => whatsapp = value ?? false);
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
                          ? 'Send immediately'
                          : _date(scheduledAt!),
                    ),
                    trailing: const Icon(Icons.schedule_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: scheduledAt ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );

                      if (picked != null) {
                        setDialogState(() => scheduledAt = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Queue'),
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

      final targets = targetsController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      final now = DateTime.now();
      final user = sl<GetCurrentUserUseCase>()();
      final keySource =
          '${titleController.text.trim()}|'
          '${bodyController.text.trim()}|'
          '${audience.name}|'
          '${targets.join(',')}|'
          '${scheduledAt?.toIso8601String() ?? 'now'}';

      final deduplicationKey = keySource.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]+'),
        '_',
      );

      context.read<CommunicationBroadcastBloc>().add(
        QueueCommunicationBroadcastRequested(
          CommunicationBroadcastEntity(
            id:
                'broadcast_'
                '${now.microsecondsSinceEpoch}',
            title: titleController.text.trim(),
            body: bodyController.text.trim(),
            channels: channels,
            audienceType: audience,
            targetIds: targets,
            status: scheduledAt != null
                ? CommunicationBroadcastStatus.scheduled
                : CommunicationBroadcastStatus.queued,
            createdBy: user?.uid ?? '',
            createdAt: now,
            updatedAt: now,
            scheduledAt: scheduledAt,
            attachmentUrl: attachmentController.text.trim(),
            deduplicationKey: deduplicationKey,
          ),
        ),
      );
    }

    titleController.dispose();
    bodyController.dispose();
    targetsController.dispose();
    attachmentController.dispose();
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
              : '${word[0].toUpperCase()}'
                    '${word.substring(1)}',
        )
        .join(' ');
  }
}
