import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/result_analytics_entity.dart';

class ResultsPieChart extends StatelessWidget {
  const ResultsPieChart({required this.title, required this.points, super.key});

  final String title;
  final List<ResultChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = _chartColors(Theme.of(context).colorScheme);
    return _ChartCard(
      title: title,
      child: points.isEmpty || points.every((point) => point.value == 0)
          ? const _ChartEmpty()
          : PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: List.generate(points.length, (index) {
                  final point = points[index];
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: point.value,
                    title: '${point.label}\n${point.value.toStringAsFixed(0)}',
                    radius: 76,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  );
                }),
              ),
            ),
    );
  }
}

class ResultsBarChart extends StatelessWidget {
  const ResultsBarChart({
    required this.title,
    required this.points,
    this.maxY = 100,
    this.valueSuffix = '%',
    super.key,
  });

  final String title;
  final List<ResultChartPoint> points;
  final double maxY;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final colors = _chartColors(Theme.of(context).colorScheme);
    final maximum = points.isEmpty
        ? maxY
        : [
            maxY,
            ...points.map((point) => point.value),
          ].reduce((first, second) => first > second ? first : second);
    return _ChartCard(
      title: title,
      child: points.isEmpty
          ? const _ChartEmpty()
          : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maximum == 0 ? 1 : maximum * 1.15,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final point = points[group.x.toInt()];
                      return BarTooltipItem(
                        '${point.label}\n${point.value.toStringAsFixed(1)}$valueSuffix',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _short(points[index].label),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  points.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: points[index].value,
                        color: colors[index % colors.length],
                        width: points.length > 8 ? 12 : 20,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class ResultsLineChart extends StatelessWidget {
  const ResultsLineChart({
    required this.title,
    required this.points,
    super.key,
  });

  final String title;
  final List<ResultChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _ChartCard(
      title: title,
      child: points.isEmpty
          ? const _ChartEmpty()
          : LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(drawVerticalLine: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touched) => touched
                        .map(
                          (spot) => LineTooltipItem(
                            '${points[spot.x.toInt()].label}\n${spot.y.toStringAsFixed(1)}%',
                            const TextStyle(color: Colors.white),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _short(points[index].label),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      points.length,
                      (index) => FlSpot(index.toDouble(), points[index].value),
                    ),
                    isCurved: true,
                    color: scheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: scheme.primary,
                            strokeColor: scheme.surface,
                            strokeWidth: 2,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: scheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('No published result data for this selection.'));
}

List<Color> _chartColors(ColorScheme colors) => [
  colors.primary,
  colors.tertiary,
  Colors.green.shade600,
  Colors.orange.shade700,
  Colors.indigo.shade500,
  Colors.pink.shade500,
  Colors.teal.shade600,
];

String _short(String value) {
  final trimmed = value.trim();
  return trimmed.length <= 9 ? trimmed : '${trimmed.substring(0, 8)}…';
}
