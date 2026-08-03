import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../bloc/communication_audit_bloc.dart';
import '../bloc/communication_audit_event.dart';
import '../bloc/communication_audit_state.dart';

class CommunicationAuditPage extends StatelessWidget {
  const CommunicationAuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CommunicationAuditBloc>()..add(const LoadCommunicationAudit()),
      child: const _CommunicationAuditView(),
    );
  }
}

class _CommunicationAuditView extends StatelessWidget {
  const _CommunicationAuditView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Tracking & Audit'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocBuilder<CommunicationAuditBloc, CommunicationAuditState>(
        builder: (context, state) {
          if (state is CommunicationAuditInitial ||
              state is CommunicationAuditLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CommunicationAuditFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as CommunicationAuditLoaded;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(title: 'Total', value: data.summary.total),
                  _MetricCard(title: 'Sent', value: data.summary.sent),
                  _MetricCard(
                    title: 'Delivered',
                    value: data.summary.delivered,
                  ),
                  _MetricCard(title: 'Read', value: data.summary.read),
                  _MetricCard(title: 'Failed', value: data.summary.failed),
                  _MetricCard(
                    title: 'Scheduled',
                    value: data.summary.scheduled,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Broadcast Delivery',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...data.broadcasts
                  .take(20)
                  .map(
                    (item) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.campaign_outlined),
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${item.status.name} â€¢ '
                          'Sent ${item.sentCount} â€¢ '
                          'Delivered ${item.deliveredCount} â€¢ '
                          'Read ${item.readCount} â€¢ '
                          'Failed ${item.failedCount}',
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 20),
              Text(
                'Recent Audit Activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (data.auditEntries.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('No communication audit entries found.'),
                  ),
                ),
              ...data.auditEntries
                  .take(50)
                  .map(
                    (entry) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.history_outlined),
                        ),
                        title: Text('${entry.module} â€¢ ${entry.action.name}'),
                        subtitle: Text(
                          '${entry.actorName.isEmpty ? entry.actorId : entry.actorName} â€¢ '
                          '${_date(entry.createdAt)}',
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

  static String _date(DateTime value) {
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
  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 6),
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
