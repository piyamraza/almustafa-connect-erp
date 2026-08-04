import 'package:flutter/material.dart';

class TimelineEmptyState extends StatelessWidget {
  const TimelineEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline, size: 52),
            SizedBox(height: 14),
            Text(
              'No timeline activity is available yet.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
