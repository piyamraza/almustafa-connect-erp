import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../di/service_locator.dart';
import '../../domain/entities/audit_configuration_entity.dart';
import '../bloc/audit_configuration_bloc.dart';
import '../bloc/audit_configuration_event.dart';
import '../bloc/audit_configuration_state.dart';

class AuditConfigurationPage extends StatelessWidget {
  const AuditConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<AuditConfigurationBloc>()..add(const LoadAuditConfiguration()),
      child: const _AuditConfigurationView(),
    );
  }
}

class _AuditConfigurationView extends StatelessWidget {
  const _AuditConfigurationView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logging')),
      body: BlocConsumer<AuditConfigurationBloc, AuditConfigurationState>(
        listener: (context, state) {
          if (state is AuditConfigurationLoaded && state.message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state is AuditConfigurationInitial ||
              state is AuditConfigurationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AuditConfigurationFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        context.read<AuditConfigurationBloc>().add(
                          const LoadAuditConfiguration(),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final loaded = state as AuditConfigurationLoaded;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audit Logging Level',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select how much system activity should be recorded.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      ...AuditLogLevel.values.map(
                        (level) => RadioListTile<AuditLogLevel>(
                          value: level,
                          groupValue: loaded.configuration.level,
                          onChanged: loaded.isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    context.read<AuditConfigurationBloc>().add(
                                      ChangeAuditLogLevel(value),
                                    );
                                  }
                                },
                          title: Text(_title(level)),
                          subtitle: Text(_description(level)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (loaded.isSaving) ...[
  const SizedBox(height: 8),
  const LinearProgressIndicator(),
],
const SizedBox(height: 24),
const Divider(),
const SizedBox(height: 16),
Text(
  'Audit Log Maintenance',
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
),
const SizedBox(height: 8),
const Text(
  'This will permanently delete all existing audit log entries.',
),
const SizedBox(height: 14),
FilledButton.icon(
  style: FilledButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.error,
    foregroundColor: Theme.of(context).colorScheme.onError,
  ),
  onPressed: loaded.isDeleting
      ? null
      : () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Delete All Audit Logs?'),
                content: const Text(
                  'All existing audit log entries will be permanently deleted. '
                  'This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(dialogContext).colorScheme.error,
                      foregroundColor:
                          Theme.of(dialogContext).colorScheme.onError,
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    child: const Text('Delete All'),
                  ),
                ],
              );
            },
          );

          if (confirmed == true && context.mounted) {
            context.read<AuditConfigurationBloc>().add(
                  const DeleteAllAuditLogs(),
                );
          }
        },
  icon: loaded.isDeleting
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Icon(Icons.delete_forever_outlined),
  label: Text(
    loaded.isDeleting
        ? 'Deleting Audit Logs...'
        : 'Delete All Audit Logs',
  ),
),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _title(AuditLogLevel level) {
    return switch (level) {
      AuditLogLevel.off => 'Off',
      AuditLogLevel.critical => 'Critical',
      AuditLogLevel.standard => 'Standard',
      AuditLogLevel.detailed => 'Detailed',
    };
  }

  static String _description(AuditLogLevel level) {
    return switch (level) {
      AuditLogLevel.off => 'Do not record any audit logs.',
      AuditLogLevel.critical =>
        'Record important security, deletion and financial activity.',
      AuditLogLevel.standard =>
        'Record critical activity plus normal create and update actions.',
      AuditLogLevel.detailed =>
        'Record standard activity plus view, print and export actions.',
    };
  }
}
