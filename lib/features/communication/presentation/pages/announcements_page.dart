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
      create: (_) =>
          sl<CommunicationBloc>()..add(const LoadCommunicationDashboard()),
      child: const _AnnouncementsView(),
    );
  }
}

class _AnnouncementsView extends StatefulWidget {
  const _AnnouncementsView();

  @override
  State<_AnnouncementsView> createState() => _AnnouncementsViewState();
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
          if (state is CommunicationInitial || state is CommunicationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CommunicationFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as CommunicationLoaded;
          final messages = data.messages.where((message) {
            final statusMatches =
                _statusFilter == null || message.status == _statusFilter;
            final audienceMatches =
                _audienceFilter == null ||
                message.audienceType == _audienceFilter;
            return statusMatches && audienceMatches;
          }).toList();

          return Column(
            children: [
              if (data.isProcessing) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 210,
                      child:
                          DropdownButtonFormField<CommunicationMessageStatus?>(
                            initialValue: _statusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
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
                      child:
                          DropdownButtonFormField<CommunicationAudienceType?>(
                            initialValue: _audienceFilter,
                            decoration: const InputDecoration(
                              labelText: 'Audience',
                            ),
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
                    ? const Center(child: Text('No announcements found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: messages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                                '${_label(message.audienceType.name)} â€¢ '
                                '${_label(message.status.name)}'
                                '${message.isExpired ? ' â€¢ Expired' : ''}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditor(context, existing: message);
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
    final titleController = TextEditingController(text: existing?.title ?? '');
    final bodyController = TextEditingController(text: existing?.body ?? '');
    final attachmentController = TextEditingController(
      text: existing?.attachmentUrl ?? '',
    );
    final targetsController = TextEditingController(
      text: existing?.targetIds.join(', ') ?? '',
    );

    var audience =
        existing?.audienceType ?? CommunicationAudienceType.wholeSchool;
    var status = existing?.status ?? CommunicationMessageStatus.draft;
    var isPinned = existing?.isPinned ?? false;
    var inApp = existing?.channels.contains(CommunicationChannel.inApp) ?? true;
    var push =
        existing?.channels.contains(CommunicationChannel.pushNotification) ??
        false;
    var whatsapp =
        existing?.channels.contains(CommunicationChannel.whatsapp) ?? false;
    DateTime? scheduledAt = existing?.scheduledAt;
    DateTime? expiresAt = existing?.expiresAt;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'New Announcement' : 'Edit Announcement',
          ),
          content: SizedBox(
            width: 560,
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
                      labelText: 'Target IDs (comma separated, optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CommunicationMessageStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
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
                      setDialogState(() => isPinned = value ?? false);
                    },
                  ),
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
                          ? 'Not scheduled'
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Expiry Date'),
                    subtitle: Text(
                      expiresAt == null ? 'No expiry' : _date(expiresAt!),
                    ),
                    trailing: const Icon(Icons.event_busy_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: expiresAt ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => expiresAt = picked);
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
            id: existing?.id ?? 'communication_${now.microsecondsSinceEpoch}',
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
            createdBy: existing?.createdBy ?? user?.uid ?? '',
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            scheduledAt: status == CommunicationMessageStatus.scheduled
                ? scheduledAt
                : null,
            publishedAt: status == CommunicationMessageStatus.published
                ? existing?.publishedAt ?? now
                : null,
            expiresAt: expiresAt,
            attachmentUrl: attachmentController.text.trim(),
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
        content: Text('Delete "${message.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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
