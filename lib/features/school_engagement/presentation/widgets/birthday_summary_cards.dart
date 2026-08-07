import 'package:flutter/material.dart';

const _borderColor = Color(0xFFE1E6ED);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

class BirthdaySummaryCards extends StatelessWidget {
  const BirthdaySummaryCards({
    super.key,
    required this.todayCount,
    required this.tomorrowCount,
    required this.weekCount,
    required this.monthCount,
  });

  final int todayCount;
  final int tomorrowCount;
  final int weekCount;
  final int monthCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _SummaryCard(
            title: "Today's Birthdays",
            value: '$todayCount',
            subtitle: 'Celebrating today',
            icon: Icons.cake_outlined,
            accent: const Color(0xFFE54868),
          ),
          _SummaryCard(
            title: 'Tomorrow',
            value: '$tomorrowCount',
            subtitle: 'Coming tomorrow',
            icon: Icons.celebration_outlined,
            accent: const Color(0xFF8B5CF6),
          ),
          _SummaryCard(
            title: 'This Week',
            value: '$weekCount',
            subtitle: 'Upcoming this week',
            icon: Icons.calendar_view_week_outlined,
            accent: const Color(0xFF246BFD),
          ),
          _SummaryCard(
            title: 'This Month',
            value: '$monthCount',
            subtitle: 'Upcoming this month',
            icon: Icons.calendar_month_outlined,
            accent: const Color(0xFF17A66B),
          ),
        ];

        final width = constraints.maxWidth;

        final columns = width >= 1100
            ? 4
            : width >= 650
                ? 2
                : 1;

        const spacing = 16.0;

        final cardWidth =
            (width - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: cardWidth,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 27,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
