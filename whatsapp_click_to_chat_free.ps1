[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\whatsapp_click_to_chat_$stamp"

function Full([string]$Path) { Join-Path $root $Path }

function WriteUtf8([string]$Path,[string]$Text) {
  $full = Full $Path
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
  throw 'PROJECT ROOT ERROR: Run from Flutter project root.'
}

$page = 'lib/features/communication/presentation/pages/whatsapp_dashboard_page.dart'

if (-not (Test-Path (Full $page))) {
  throw "REQUIRED FILE ERROR: $page"
}

$pubspec = [IO.File]::ReadAllText((Full 'pubspec.yaml'))

if (-not $pubspec.Contains('url_launcher:')) {
  throw 'DEPENDENCY ERROR: url_launcher is missing from pubspec.yaml.'
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
BackupFile $page

WriteUtf8 $page @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/whatsapp_template_entity.dart';
import '../bloc/whatsapp_bloc.dart';
import '../bloc/whatsapp_event.dart';
import '../bloc/whatsapp_state.dart';

class WhatsAppDashboardPage extends StatelessWidget {
  const WhatsAppDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<WhatsAppBloc>()..add(const LoadWhatsAppDashboard()),
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
        title: const Text('WhatsApp Click-to-Chat'),
        actions: const [DashboardNavigationButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSendDialog(context),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Open WhatsApp'),
      ),
      body: BlocConsumer<WhatsAppBloc, WhatsAppState>(
        listener: (context, state) {
          if (state is! WhatsAppLoaded) return;

          final text = state.error ?? state.message;
          if (text == null) return;

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(text)),
            );
        },
        builder: (context, state) {
          if (state is WhatsAppInitial ||
              state is WhatsAppLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is WhatsAppFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as WhatsAppLoaded;

          return Column(
            children: [
              if (data.isProcessing)
                const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        'Templates: ${data.templates.length}',
                      ),
                    ),
                    const Chip(
                      avatar: Icon(
                        Icons.check_circle_outline,
                        size: 18,
                      ),
                      label: Text(
                        'No Meta approval required',
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          _showTemplateDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New Template'),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Free Click-to-Chat Mode'),
                    subtitle: Text(
                      'The ERP opens WhatsApp Web or the WhatsApp app '
                      'with the recipient and message already filled. '
                      'Review the message and press Send in WhatsApp.',
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  children: [
                    Text(
                      'Message Templates',
                      style:
                          Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (data.templates.isEmpty)
                      const Card(
                        child: ListTile(
                          title: Text(
                            'No WhatsApp templates found.',
                          ),
                          subtitle: Text(
                            'Create a template for fee reminders, '
                            'holidays, attendance or notices.',
                          ),
                        ),
                      ),
                    ...data.templates.map(
                      (template) => Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(
                              Icons.description_outlined,
                            ),
                          ),
                          title: Text(template.name),
                          subtitle: Text(
                            '${template.languageCode} - Ready to use',
                          ),
                          trailing: IconButton(
                            tooltip: 'Use Template',
                            onPressed: () => _showSendDialog(
                              context,
                              initialTemplate: template,
                            ),
                            icon: const Icon(
                              Icons.send_outlined,
                            ),
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

  static Future<void> _showTemplateDialog(
    BuildContext context,
  ) async {
    final nameController = TextEditingController();
    final languageController =
        TextEditingController(text: 'en');
    final bodyController = TextEditingController();
    final variablesController =
        TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New WhatsApp Template'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Template Name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: languageController,
                  decoration: const InputDecoration(
                    labelText: 'Language Code',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    helperText:
                        'Use variables like {{StudentName}}, '
                        '{{Amount}} and {{DueDate}}.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: variablesController,
                  decoration: const InputDecoration(
                    labelText:
                        'Variable Names (comma separated)',
                    helperText:
                        'Example: StudentName, Amount, DueDate',
                  ),
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
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();
      final user = sl<GetCurrentUserUseCase>()();

      context.read<WhatsAppBloc>().add(
            SaveWhatsAppTemplateRequested(
              WhatsAppTemplateEntity(
                id: 'wa_template_${now.microsecondsSinceEpoch}',
                name: nameController.text.trim(),
                languageCode:
                    languageController.text.trim(),
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

  static Future<void> _showSendDialog(
    BuildContext context, {
    WhatsAppTemplateEntity? initialTemplate,
  }) async {
    final state = context.read<WhatsAppBloc>().state;
    if (state is! WhatsAppLoaded) return;

    final phoneController = TextEditingController();
    final messageController = TextEditingController();

    WhatsAppTemplateEntity? selectedTemplate =
        initialTemplate ??
            (state.templates.isEmpty
                ? null
                : state.templates.first);

    if (selectedTemplate != null) {
      messageController.text = selectedTemplate.body;
    }

    final open = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) =>
            AlertDialog(
          title: const Text('Open WhatsApp Chat'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText:
                          'Recipient Phone with Country Code',
                      helperText:
                          'Pakistan example: 923001234567',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<
                      WhatsAppTemplateEntity?>(
                    initialValue: selectedTemplate,
                    decoration: const InputDecoration(
                      labelText: 'Template (optional)',
                    ),
                    items: [
                      const DropdownMenuItem<
                          WhatsAppTemplateEntity?>(
                        value: null,
                        child: Text('Custom Message'),
                      ),
                      ...state.templates.map(
                        (item) => DropdownMenuItem<
                            WhatsAppTemplateEntity?>(
                          value: item,
                          child: Text(item.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedTemplate = value;
                        if (value != null) {
                          messageController.text =
                              value.body;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    maxLines: 9,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      helperText:
                          'Replace any {{variables}} before opening WhatsApp.',
                    ),
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
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open WhatsApp'),
            ),
          ],
        ),
      ),
    );

    if (open == true && context.mounted) {
      final phone =
          _normalizePhone(phoneController.text);

      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter a valid recipient phone number.',
            ),
          ),
        );
      } else if (messageController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a message.'),
          ),
        );
      } else {
        final uri = Uri.https(
          'wa.me',
          '/$phone',
          {'text': messageController.text.trim()},
        );

        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'WhatsApp could not be opened.',
              ),
            ),
          );
        }
      }
    }

    phoneController.dispose();
    messageController.dispose();
  }

  static String _normalizePhone(String value) {
    var phone =
        value.replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.startsWith('00')) {
      phone = phone.substring(2);
    }

    if (phone.startsWith('0') &&
        phone.length == 11) {
      phone = '92${phone.substring(1)}';
    }

    return phone;
  }
}
'@

& dart format $page

if ($LASTEXITCODE -ne 0) {
  throw "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze `
  lib/features/communication `
  --no-fatal-infos `
  --no-fatal-warnings

if ($LASTEXITCODE -ne 0) {
  throw "COMMUNICATION ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'WhatsApp Click-to-Chat installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'No Meta API, approval, token, or messaging charges are required.' -ForegroundColor Yellow
Write-Host 'The user must review and press Send inside WhatsApp.' -ForegroundColor Yellow
