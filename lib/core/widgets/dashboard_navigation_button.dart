import 'package:flutter/material.dart';

class DashboardNavigationButton extends StatelessWidget {
  const DashboardNavigationButton({super.key});

  void _openDashboard(BuildContext context) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: compact
          ? SizedBox.square(
              dimension: 40,
              child: IconButton.filledTonal(
                tooltip: 'Dashboard',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                onPressed: () => _openDashboard(context),
                icon: const Icon(Icons.space_dashboard_rounded, size: 18),
              ),
            )
          : FilledButton.tonalIcon(
              onPressed: () => _openDashboard(context),
              icon: const Icon(Icons.space_dashboard_rounded, size: 18),
              label: const Text('Dashboard'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                visualDensity: VisualDensity.compact,
              ),
            ),
    );
  }
}
