import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/communication_analytics_entity.dart';

class CommunicationMetricCard extends StatelessWidget {
  const CommunicationMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunicationChannelComparison extends StatelessWidget {
  const CommunicationChannelComparison({required this.items, super.key});

  final List<CommunicationChannelAnalyticsEntity> items;

  @override
  Widget build(BuildContext context) {
    final maximum = items.fold<int>(
      1,
      (current, item) => math.max(current, item.total),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Channel Comparison',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(item.channel)),
                        Text('${item.total}'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: item.total / maximum),
                    const SizedBox(height: 4),
                    Text(
                      'Sent ${item.sent} â€¢ Delivered ${item.delivered} â€¢ '
                      'Read ${item.read} â€¢ Failed ${item.failed}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunicationMonthlyTrendChart extends StatelessWidget {
  const CommunicationMonthlyTrendChart({required this.items, super.key});

  final List<CommunicationMonthlyTrendEntity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No monthly communication trend available.'),
          ),
        ),
      );
    }

    final maximum = items.fold<int>(
      1,
      (current, item) => math.max(current, item.total),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Communication Trend',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: items.map((item) {
                  final height = 150 * item.total / maximum;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: math.max(5, height),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.75),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.month.month.toString().padLeft(2, '0')}/'
                            '${item.month.year.toString().substring(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunicationTopAudiences extends StatelessWidget {
  const CommunicationTopAudiences({required this.items, super.key});

  final List<CommunicationAudienceAnalyticsEntity> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Audiences',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty) const Text('No audience data available.'),
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
                title: Text(_label(item.audience)),
                trailing: Text('${item.total}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _label(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}'
                    '${word.substring(1)}',
        )
        .join(' ');
  }
}

class CommunicationRecentActivity extends StatelessWidget {
  const CommunicationRecentActivity({required this.items, super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Communication Activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty) const Text('No recent activity found.'),
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_outlined),
                title: Text(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
