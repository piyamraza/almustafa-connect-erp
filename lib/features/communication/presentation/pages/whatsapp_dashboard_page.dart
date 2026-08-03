import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/whatsapp_message_request_entity.dart';
import '../../domain/entities/whatsapp_template_entity.dart';
import '../bloc/whatsapp_bloc.dart';
import '../bloc/whatsapp_event.dart';
import '../bloc/whatsapp_state.dart';
import 'whatsapp_broadcast_page.dart';

class WhatsAppDashboardPage extends StatelessWidget {
  const WhatsAppDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WhatsAppBloc>()..add(const LoadWhatsAppDashboard()),
      child: const _WhatsAppDashboardView(),
    );
  }
}

class _WhatsAppDashboardView extends StatelessWidget {
  const _WhatsAppDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Integration'),
        actions: const [DashboardNavigationButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSendDialog(context),
        icon: const Icon(Icons.send),
        label: const Text('Send WhatsApp'),
      ),
      body: BlocConsumer<WhatsAppBloc, WhatsAppState>(
        listener: (context, state) {
          if (state is! WhatsAppLoaded) return;
          final text = state.error ?? state.message;
          if (text == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
        },
        builder: (context, state) {
          if (state is WhatsAppInitial || state is WhatsAppLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WhatsAppFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as WhatsAppLoaded;
          final approved = data.templates
              .where((item) => item.status == WhatsAppTemplateStatus.approved)
              .length;
          final failed = data.requests
              .where((item) => item.status == WhatsAppMessageStatus.failed)
              .length;

          return Column(
            children: [
              if (data.isProcessing) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Chip(label: Text('Templates: ${data.templates.length}')),
                    Chip(label: Text('Approved: $approved')),
                    Chip(label: Text('Messages: ${data.requests.length}')),
                    Chip(label: Text('Failed: $failed')),
                    FilledButton.tonalIcon(
                      onPressed: () => _showTemplateDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New Template'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BlocProvider.value(
                              value: context.read<WhatsAppBloc>(),
                              child: const WhatsAppBroadcastPage(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.campaign_outlined),
                      label: const Text('Broadcasts'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  children: [
                    Text(
                      'Templates',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (data.templates.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text('No WhatsApp templates found.'),
                        ),
                      ),
                    ...data.templates.map(
                      (template) => Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.description_outlined),
                          ),
                          title: Text(template.name),
                          subtitle: Text(
                            '${template.languageCode} â€¢ '
                            '${template.status.name}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Recent Requests',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (data.requests.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text('No WhatsApp requests found.'),
                        ),
                      ),
                    ...data.requests
                        .take(20)
                        .map(
                          (request) => Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.chat_outlined),
                              ),
                              title: Text(request.recipientPhone),
                              subtitle: Text(
                                '${request.templateName} â€¢ '
                                '${request.status.name}',
                              ),
                              trailing: Text(
                                '${request.createdAt.day.toString().padLeft(2, '0')}-'
                                '${request.createdAt.month.toString().padLeft(2, '0')}-'
                                '${request.createdAt.year}',
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _showTemplateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final languageController = TextEditingController(text: 'en');
    final bodyController = TextEditingController();
    final variablesController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New WhatsApp Template'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Template Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: languageController,
                decoration: const InputDecoration(labelText: 'Language Code'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Template Body'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: variablesController,
                decoration: const InputDecoration(
                  labelText: 'Variable Names (comma separated)',
                ),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();
      final user = sl<GetCurrentUserUseCase>()();

      context.read<WhatsAppBloc>().add(
        SaveWhatsAppTemplateRequested(
          WhatsAppTemplateEntity(
            id: 'wa_template_${now.microsecondsSinceEpoch}',
            name: nameController.text.trim(),
            languageCode: languageController.text.trim(),
            body: bodyController.text.trim(),
            variableNames: variablesController.text
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList(),
            status: WhatsAppTemplateStatus.draft,
            createdBy: user?.uid ?? '',
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
    }

    nameController.dispose();
    languageController.dispose();
    bodyController.dispose();
    variablesController.dispose();
  }

  static Future<void> _showSendDialog(BuildContext context) async {
    final state = context.read<WhatsAppBloc>().state;
    if (state is! WhatsAppLoaded) return;

    final approvedTemplates = state.templates
        .where((item) => item.status == WhatsAppTemplateStatus.approved)
        .toList();

    if (approvedTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No approved WhatsApp template is available.'),
        ),
      );
      return;
    }

    final phoneController = TextEditingController();
    final parametersController = TextEditingController();
    final attachmentController = TextEditingController();
    var selectedTemplate = approvedTemplates.first;

    final send = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Send WhatsApp Message'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Phone with Country Code',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<WhatsAppTemplateEntity>(
                  initialValue: selectedTemplate,
                  decoration: const InputDecoration(
                    labelText: 'Approved Template',
                  ),
                  items: approvedTemplates
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedTemplate = value);
                    }
                  },
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
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );

    if (send == true && context.mounted) {
      final parameters = <String, String>{};
      for (final pair in parametersController.text.split(',')) {
        final parts = pair.split('=');
        if (parts.length >= 2) {
          parameters[parts.first.trim()] = parts.sublist(1).join('=').trim();
        }
      }

      final now = DateTime.now();
      final user = sl<GetCurrentUserUseCase>()();

      context.read<WhatsAppBloc>().add(
        SendWhatsAppMessageRequested(
          WhatsAppMessageRequestEntity(
            id: 'wa_request_${now.microsecondsSinceEpoch}',
            recipientPhone: phoneController.text.trim(),
            templateName: selectedTemplate.name,
            languageCode: selectedTemplate.languageCode,
            parameters: parameters,
            status: WhatsAppMessageStatus.queued,
            createdBy: user?.uid ?? '',
            createdAt: now,
            updatedAt: now,
            attachmentUrl: attachmentController.text.trim(),
          ),
        ),
      );
    }

    phoneController.dispose();
    parametersController.dispose();
    attachmentController.dispose();
  }
}
