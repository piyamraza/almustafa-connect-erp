import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../bloc/communication_bloc.dart';
import '../bloc/communication_event.dart';
import '../bloc/communication_state.dart';
import '../../../notices/presentation/pages/notices_dashboard_page.dart';
import 'in_app_chat_page.dart';
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

          final compact = MediaQuery.sizeOf(context).width < 600;
          return ListView(
            padding: EdgeInsets.all(compact ? 10 : 20),
            children: [
              _ModuleCard(
                title: 'Announcements & Circulars',
                subtitle: 'Create, schedule, publish, and archive',
                icon: Icons.campaign_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NoticesDashboardPage(),
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
                subtitle: 'Private Admin and Teacher conversations',
                icon: Icons.forum_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const InAppChatPage(),
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
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Card(
      child: ListTile(
        dense: compact,
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 16,
          vertical: compact ? 2 : 6,
        ),
        leading: CircleAvatar(
          radius: compact ? 17 : 20,
          child: Icon(icon, size: compact ? 18 : 22),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.arrow_forward, size: compact ? 18 : 24),
        onTap: onTap,
      ),
    );
  }
}
