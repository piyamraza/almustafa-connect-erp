import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/backup_record_entity.dart';
import '../../domain/entities/restore_request_entity.dart';
import '../bloc/backup_bloc.dart';
import '../bloc/backup_event.dart';
import '../bloc/backup_state.dart';

class BackupRestorePage extends StatelessWidget {
  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BackupBloc>()..add(const LoadBackupData()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup and Restore'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<BackupBloc, BackupState>(
        listener: (context, state) {
          if (state is BackupLoaded && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state is BackupInitial || state is BackupLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BackupFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as BackupLoaded;
          final completed = data.backups
              .where((item) => item.status == BackupStatus.completed)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => _backup(context),
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('Create Backup'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: completed.isEmpty
                        ? null
                        : () => _restore(context, completed),
                    icon: const Icon(Icons.restore_outlined),
                    label: const Text('Request Restore'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Backup History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (data.backups.isEmpty)
                const Card(child: ListTile(title: Text('No backups found.'))),
              ...data.backups.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(
                      item.fileName.isEmpty ? item.id : item.fileName,
                    ),
                    subtitle: Text(
                      '${_date(item.requestedAt)} - ${item.status.name}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Restore Requests',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (data.restoreRequests.isEmpty)
                const Card(
                  child: ListTile(title: Text('No restore requests found.')),
                ),
              ...data.restoreRequests.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.backupFileName),
                    subtitle: Text(
                      '${_date(item.requestedAt)} - ${item.status.name}',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _backup(BuildContext context) async {
    final notes = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Backup'),
        content: TextField(
          controller: notes,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final user = sl<GetCurrentUserUseCase>()();
      context.read<BackupBloc>().add(
        CreateBackupRequested(user?.uid ?? '', notes.text.trim()),
      );
    }

    notes.dispose();
  }

  static Future<void> _restore(
    BuildContext context,
    List<BackupRecordEntity> backups,
  ) async {
    var selected = backups.first;
    final confirm = TextEditingController();
    final notes = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request Restore'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<BackupRecordEntity>(
                  initialValue: selected,
                  isExpanded: true,
                  items: backups
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.fileName.isEmpty ? e.id : e.fileName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selected = value);
                  },
                  decoration: const InputDecoration(labelText: 'Backup'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirm,
                  decoration: const InputDecoration(labelText: 'Type RESTORE'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Reason'),
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
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      final now = DateTime.now();
      final user = sl<GetCurrentUserUseCase>()();

      context.read<BackupBloc>().add(
        CreateRestoreRequestRequested(
          RestoreRequestEntity(
            id: 'restore_${now.microsecondsSinceEpoch}',
            backupId: selected.id,
            backupFileName: selected.fileName.isEmpty
                ? selected.id
                : selected.fileName,
            requestedBy: user?.uid ?? '',
            requestedAt: now,
            status: RestoreStatus.requested,
            confirmationText: confirm.text.trim(),
            notes: notes.text.trim(),
          ),
        ),
      );
    }

    confirm.dispose();
    notes.dispose();
  }

  static String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year}';
  }
}
