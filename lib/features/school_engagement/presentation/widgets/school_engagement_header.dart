import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard_navigation_button.dart';

const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

class SchoolEngagementHeader extends StatelessWidget {
  const SchoolEngagementHeader({
    super.key,
    required this.onRefresh,
    required this.onHistory,
  });

  final Future<void> Function() onRefresh;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardNavigationButton(),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birthdays',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage student birthdays, wishes and birthday cards',
                    style: TextStyle(color: _textSecondary, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        );

        final actions = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            OutlinedButton.icon(
              onPressed: onHistory,
              icon: const Icon(Icons.history),
              label: const Text('History'),
            ),
          ],
        );

        if (constraints.maxWidth < 800) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 18), actions],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }
}
