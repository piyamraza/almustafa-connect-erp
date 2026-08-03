import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../bloc/communication_bloc.dart';
import '../bloc/communication_event.dart';
import '../bloc/communication_state.dart';
import 'announcements_page.dart';
import 'communication_broadcast_page.dart';
import 'communication_audit_page.dart';
import 'communication_analytics_page.dart';
import 'in_app_chat_page.dart';
import 'push_notification_history_page.dart';
import 'whatsapp_dashboard_page.dart';

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
              _ModuleCard(
                title: 'Push Notifications',
                subtitle: 'History, delivery logs, and failed retries',
                icon: Icons.notifications_active_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PushNotificationHistoryPage(),
                    ),
                  );
                },
              ),
              _ModuleCard(
                title: 'WhatsApp Integration',
                subtitle: 'Templates, sending requests, and history',
                icon: Icons.chat_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WhatsAppDashboardPage(),
                    ),
                  );
                },
              ),
              _ModuleCard(
                title: 'In-App Chat',
                subtitle: 'Admin, teacher, and parent conversations',
                icon: Icons.forum_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const InAppChatPage(),
                    ),
                  );
                },
              ),
              _ModuleCard(
                title: 'Broadcast Messages',
                subtitle: 'In-App, Push, and WhatsApp broadcasts',
                icon: Icons.cell_tower_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CommunicationBroadcastPage(),
                    ),
                  );
                },
              ),
              _ModuleCard(
                title: 'Communication Analytics',
                subtitle: 'Channel performance, trends, and failure rates',
                icon: Icons.analytics_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CommunicationAnalyticsPage(),
                    ),
                  );
                },
              ),
              _ModuleCard(
                title: 'Delivery Tracking & Audit',
                subtitle: 'Sent, delivered, read, failed, and audit history',
                icon: Icons.history_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CommunicationAuditPage(),
                    ),
                  );
                },
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
