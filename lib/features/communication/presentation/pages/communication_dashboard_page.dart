import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../bloc/communication_bloc.dart';
import '../bloc/communication_event.dart';
import '../bloc/communication_state.dart';
import 'announcements_page.dart';

class CommunicationDashboardPage extends StatelessWidget {
  const CommunicationDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CommunicationBloc>()..add(const LoadCommunicationDashboard()),
      child: const _CommunicationDashboardView(),
    );
  }
}

class _CommunicationDashboardView extends StatelessWidget {
  const _CommunicationDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocBuilder<CommunicationBloc, CommunicationState>(
        builder: (context, state) {
          if (state is CommunicationInitial || state is CommunicationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CommunicationFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as CommunicationLoaded;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    title: 'Total Messages',
                    value: data.messages.length,
                    icon: Icons.forum_outlined,
                  ),
                  _SummaryCard(
                    title: 'Published',
                    value: data.publishedCount,
                    icon: Icons.campaign_outlined,
                  ),
                  _SummaryCard(
                    title: 'Scheduled',
                    value: data.scheduledCount,
                    icon: Icons.schedule_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _ModuleCard(
                title: 'Announcements & Circulars',
                subtitle: 'Create, schedule, publish, and archive',
                icon: Icons.campaign_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AnnouncementsPage(),
                    ),
                  );
                },
              ),
              const _ModuleCard(
                title: 'Push Notifications',
                subtitle: 'Phase 3',
                icon: Icons.notifications_active_outlined,
              ),
              const _ModuleCard(
                title: 'WhatsApp Integration',
                subtitle: 'Phase 4',
                icon: Icons.chat_outlined,
              ),
              const _ModuleCard(
                title: 'In-App Chat',
                subtitle: 'Phase 5',
                icon: Icons.forum_outlined,
              ),
              const _ModuleCard(
                title: 'Broadcast Messages',
                subtitle: 'Phase 6',
                icon: Icons.cell_tower_outlined,
              ),
              const _ModuleCard(
                title: 'Communication History',
                subtitle: 'Phase 7',
                icon: Icons.history_outlined,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
