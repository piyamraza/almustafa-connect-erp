import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/services/access_control_migration_service.dart';

class AccessControlProductionReadinessPage extends StatefulWidget {
  const AccessControlProductionReadinessPage({super.key});

  @override
  State<AccessControlProductionReadinessPage> createState() =>
      _AccessControlProductionReadinessPageState();
}

class _AccessControlProductionReadinessPageState
    extends State<AccessControlProductionReadinessPage> {
  late final AccessControlMigrationService _migrationService;
  bool _busy = false;
  List<String>? _issues;
  String? _message;

  @override
  void initState() {
    super.initState();
    _migrationService = AccessControlMigrationService(sl<FirebaseFirestore>());
  }

  Future<void> _migrate() async {
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final result = await _migrationService.migrateUserRoleDocumentsToUidIds();

      if (!mounted) return;

      setState(() {
        _message =
            'Scanned ${result.scanned}; migrated ${result.migrated}; '
            'skipped ${result.skipped}; removed legacy '
            '${result.deletedLegacy}.';
      });

      await _validate();
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Migration failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _validate() async {
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final issues = await _migrationService.validateProductionReadiness();

      if (!mounted) return;

      setState(() {
        _issues = issues;
        _message = issues.isEmpty
            ? 'Production readiness validation passed.'
            : 'Resolve all issues before deploying Firestore rules.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Validation failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final issues = _issues;

    return Scaffold(
      appBar: AppBar(title: const Text('Access Control Production Readiness')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Run migration first. Then validate. Deploy '
                'firestore.rules only when validation passes and an '
                'active Super Admin assignment exists.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _migrate,
                icon: const Icon(Icons.sync_alt),
                label: const Text('Migrate User Roles to UID IDs'),
              ),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _validate,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Validate Production Readiness'),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_message != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_message!),
              ),
            ),
          ],
          if (issues != null) ...[
            const SizedBox(height: 16),
            Text(
              issues.isEmpty ? 'Validation Passed' : 'Blocking Issues',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (issues.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text(
                    'UID role documents and active Super Admin verified.',
                  ),
                ),
              )
            else
              for (final issue in issues)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text(issue),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
