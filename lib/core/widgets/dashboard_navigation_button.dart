import 'package:flutter/material.dart';

class DashboardNavigationButton extends StatelessWidget {
  const DashboardNavigationButton({super.key});

  void _openDashboard(BuildContext context) {
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: () => _openDashboard(context),
        icon: const Icon(Icons.dashboard_outlined, size: 18),
        label: const Text('DASHBOARD'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
