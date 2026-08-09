import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/whatsapp_broadcast_entity.dart';
import '../../domain/entities/whatsapp_template_entity.dart';
import '../bloc/whatsapp_broadcast_bloc.dart';
import '../bloc/whatsapp_broadcast_event.dart';
import '../bloc/whatsapp_broadcast_state.dart';
import '../bloc/whatsapp_bloc.dart';
import '../bloc/whatsapp_state.dart';

class WhatsAppBroadcastPage extends StatelessWidget {
  const WhatsAppBroadcastPage({super.key});

  @override
  Widget build(BuildContext context) {
    final whatsappState = context.read<WhatsAppBloc>().state;
    final templates = whatsappState is WhatsAppLoaded
        ? whatsappState.templates
              .where((item) => item.status == WhatsAppTemplateStatus.approved)
              .toList()
        : <WhatsAppTemplateEntity>[];

    return BlocProvider(
      create: (_) =>
          sl<WhatsAppBroadcastBloc>()..add(const LoadWhatsAppBroadcasts()),
      child: _WhatsAppBroadcastView(templates: templates),
    );
  }
}

class _WhatsAppBroadcastView extends StatelessWidget {
  const _WhatsAppBroadcastView({required this.templates});

  final List<WhatsAppTemplateEntity> templates;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Broadcasts'),
        actions: const [DashboardNavigationButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: templates.isEmpty
            ? null
            : () => _showBroadcastDialog(context),
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('New Broadcast'),
      ),
      body: BlocConsumer<WhatsAppBroadcastBloc, WhatsAppBroadcastState>(
        listener: (context, state) {
          if (state is! WhatsAppBroadcastLoaded) return;
          final text = state.error ?? state.message;
          if (text == null) return;

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
        },
        builder: (context, state) {
          if (state is WhatsAppBroadcastInitial ||
              state is WhatsAppBroadcastLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WhatsAppBroadcastFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as WhatsAppBroadcastLoaded;

          return Column(
            children: [
              if (data.isProcessing) const LinearProgressIndicator(),
              if (templates.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Card(
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text(
                        'No approved WhatsApp template is available.',
                      ),
                      subtitle: Text(
                        'Approve a template before creating a broadcast.',
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: data.broadcasts.isEmpty
                    ? const Center(child: Text('No WhatsApp broadcasts found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: data.broadcasts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = data.broadcasts[index];

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(
                                  item.status == WhatsAppBroadcastStatus.failed
                                      ? Icons.error_outline
                                      : Icons.campaign_outlined,
                                ),
                              ),
                              title: Text(item.title),
                              subtitle: Text(
                                '${item.audience.name} | '
                                '${item.automationType.name} | '
                                '${item.status.name}',
                              ),
                              trailing:
                                  item.status ==
                                          WhatsAppBroadcastStatus.failed ||
                                      item.status ==
                                          WhatsAppBroadcastStatus
                                              .partiallyFailed
                                  ? IconButton(
                                      tooltip: 'Retry',
                                      onPressed: data.isProcessing
                                          ? null
                                          : () {
                                              context
                                                  .read<WhatsAppBroadcastBloc>()
                                                  .add(
                                                    RetryWhatsAppBroadcastRequested(
                                                      item,
                                                    ),
                                                  );
                                            },
                                      icon: const Icon(Icons.refresh),
                                    )
                                  : Text(
                                      '${item.successCount}/'
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
    final targetsController = TextEditingController();
    final parametersController = TextEditingController();
    final attachmentController = TextEditingController();

    var template = templates.first;
    var audience = WhatsAppBroadcastAudience.wholeSchool;
    var automation = WhatsAppAutomationType.manual;
    DateTime? scheduledAt;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New WhatsApp Broadcast'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Broadcast Title',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<WhatsAppTemplateEntity>(
                    initialValue: template,
                    decoration: const InputDecoration(
                      labelText: 'Approved Template',
                    ),
                    items: templates
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => template = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<WhatsAppBroadcastAudience>(
                    initialValue: audience,
                    decoration: const InputDecoration(labelText: 'Audience'),
                    items: WhatsAppBroadcastAudience.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.name),
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
                  DropdownButtonFormField<WhatsAppAutomationType>(
                    initialValue: automation,
                    decoration: const InputDecoration(
                      labelText: 'Automation Type',
                    ),
                    items: WhatsAppAutomationType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => automation = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetsController,
                    decoration: const InputDecoration(
                      labelText: 'Target IDs / Phones (comma separated)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: parametersController,
                    decoration: const InputDecoration(
                      labelText: 'Parameters: key=value, key=value',
                    ),
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
                          : '${scheduledAt!.day.toString().padLeft(2, '0')}-'
                                '${scheduledAt!.month.toString().padLeft(2, '0')}-'
                                '${scheduledAt!.year}',
                    ),
                    trailing: const Icon(Icons.schedule_outlined),
                    onTap: () async {
                      final value = await showDatePicker(
                        context: dialogContext,
                        initialDate: scheduledAt ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );

                      if (value != null) {
                        setDialogState(() => scheduledAt = value);
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
      final parameters = <String, String>{};
      for (final pair in parametersController.text.split(',')) {
        final parts = pair.split('=');
        if (parts.length >= 2) {
          parameters[parts.first.trim()] = parts.sublist(1).join('=').trim();
        }
      }

      final targets = targetsController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      final now = DateTime.now();
      final user = sl<GetCurrentUserUseCase>()();

      context.read<WhatsAppBroadcastBloc>().add(
        QueueWhatsAppBroadcastRequested(
          WhatsAppBroadcastEntity(
            id: 'wa_broadcast_${now.microsecondsSinceEpoch}',
            title: titleController.text.trim(),
            templateName: template.name,
            languageCode: template.languageCode,
            audience: audience,
            targetIds: targets,
            parameters: parameters,
            automationType: automation,
            status: WhatsAppBroadcastStatus.queued,
            createdBy: user?.uid ?? '',
            createdAt: now,
            updatedAt: now,
            attachmentUrl: attachmentController.text.trim(),
            scheduledAt: scheduledAt,
          ),
        ),
      );
    }

    titleController.dispose();
    targetsController.dispose();
    parametersController.dispose();
    attachmentController.dispose();
  }
}
