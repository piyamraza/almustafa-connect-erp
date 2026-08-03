import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../bloc/communication_analytics_bloc.dart';
import '../bloc/communication_analytics_event.dart';
import '../bloc/communication_analytics_state.dart';
import '../widgets/communication_analytics_widgets.dart';

class CommunicationAnalyticsPage extends StatelessWidget {
  const CommunicationAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CommunicationAnalyticsBloc>()
            ..add(const LoadCommunicationAnalytics()),
      child: const _CommunicationAnalyticsView(),
    );
  }
}

class _CommunicationAnalyticsView extends StatelessWidget {
  const _CommunicationAnalyticsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication Analytics'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocBuilder<CommunicationAnalyticsBloc, CommunicationAnalyticsState>(
        builder: (context, state) {
          if (state is CommunicationAnalyticsInitial ||
              state is CommunicationAnalyticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CommunicationAnalyticsFailure) {
            return Center(child: Text(state.message));
          }

          final analytics = (state as CommunicationAnalyticsLoaded).analytics;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1100
                      ? 4
                      : constraints.maxWidth >= 700
                      ? 3
                      : constraints.maxWidth >= 430
                      ? 2
                      : 1;

                  final cards = [
                    CommunicationMetricCard(
                      title: 'Total Messages',
                      value: '${analytics.totalMessages}',
                      icon: Icons.forum_outlined,
                    ),
                    CommunicationMetricCard(
                      title: 'Delivered',
                      value: '${analytics.delivered}',
                      icon: Icons.done_all,
                    ),
                    CommunicationMetricCard(
                      title: 'Read',
                      value: '${analytics.read}',
                      icon: Icons.mark_email_read_outlined,
                    ),
                    CommunicationMetricCard(
                      title: 'Failed',
                      value: '${analytics.failed}',
                      icon: Icons.error_outline,
                    ),
                    CommunicationMetricCard(
                      title: 'Scheduled',
                      value: '${analytics.scheduled}',
                      icon: Icons.schedule_outlined,
                    ),
                    CommunicationMetricCard(
                      title: 'Delivery Rate',
                      value:
                          '${(analytics.deliveryRate * 100).toStringAsFixed(1)}%',
                      icon: Icons.trending_up,
                    ),
                    CommunicationMetricCard(
                      title: 'Read Rate',
                      value:
                          '${(analytics.readRate * 100).toStringAsFixed(1)}%',
                      icon: Icons.visibility_outlined,
                    ),
                    CommunicationMetricCard(
                      title: 'Failure Rate',
                      value:
                          '${(analytics.failureRate * 100).toStringAsFixed(1)}%',
                      icon: Icons.warning_amber_outlined,
                    ),
                  ];

                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 1 ? 3.1 : 1.5,
                    children: cards,
                  );
                },
              ),
              const SizedBox(height: 18),
              CommunicationMonthlyTrendChart(items: analytics.monthlyTrend),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        CommunicationChannelComparison(
                          items: analytics.channels,
                        ),
                        const SizedBox(height: 14),
                        CommunicationTopAudiences(
                          items: analytics.topAudiences,
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CommunicationChannelComparison(
                          items: analytics.channels,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: CommunicationTopAudiences(
                          items: analytics.topAudiences,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              CommunicationRecentActivity(items: analytics.recentActivity),
            ],
          );
        },
      ),
    );
  }
}
