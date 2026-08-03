import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../bloc/system_health_bloc.dart';
import '../bloc/system_health_event.dart';
import '../bloc/system_health_state.dart';

class SystemHealthPage extends StatelessWidget {
  const SystemHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SystemHealthBloc>()..add(const LoadSystemHealth()),
      child: const _SystemHealthView(),
    );
  }
}

class _SystemHealthView extends StatelessWidget {
  const _SystemHealthView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Health and Diagnostics'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocBuilder<SystemHealthBloc, SystemHealthState>(
        builder: (context, state) {
          if (state is SystemHealthInitial || state is SystemHealthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SystemHealthFailure) {
            return Center(child: Text(state.message));
          }

          final health = (state as SystemHealthLoaded).health;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<SystemHealthBloc>().add(const RefreshSystemHealth());
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      title: 'Firestore',
                      value: health.firestoreReachable ? 'Connected' : 'Error',
                    ),
                    _MetricCard(
                      title: 'Authentication',
                      value: health.authenticated ? 'Signed In' : 'Signed Out',
                    ),
                    _MetricCard(
                      title: 'Healthy Collections',
                      value:
                          '${health.healthyCollections}/${health.collections.length}',
                    ),
                    _MetricCard(
                      title: 'Total Records',
                      value: '${health.totalRecords}',
                    ),
                    _MetricCard(
                      title: 'App Version',
                      value: '${health.appVersion}+${health.buildNumber}',
                    ),
                    _MetricCard(
                      title: 'Firebase Project',
                      value: health.firebaseProjectId,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      context.read<SystemHealthBloc>().add(
                        const RefreshSystemHealth(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Run Diagnostics'),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Collection Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...health.collections.map(
                  (item) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          item.isReachable
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                        ),
                      ),
                      title: Text(item.name),
                      subtitle: item.errorMessage.isEmpty
                          ? null
                          : Text(item.errorMessage),
                      trailing: Text(
                        item.isReachable
                            ? '${item.recordCount} records'
                            : 'Unavailable',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'About ERP',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Card(
                  child: ListTile(
                    title: Text('Almustafa Connect ERP'),
                    subtitle: Text('School Management System - Version 1.0'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Last Diagnostic Check'),
                    subtitle: Text(_dateTime(health.checkedAt)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _dateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
