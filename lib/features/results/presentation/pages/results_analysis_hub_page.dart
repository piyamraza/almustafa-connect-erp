import 'package:flutter/material.dart';

import 'results_analytics_page.dart';

class ResultsAnalysisHubPage extends StatelessWidget {
  const ResultsAnalysisHubPage({super.key});

  static const _items = [
    _AnalysisItem(
      title: 'Overall Statistics',
      description: 'Review published-result performance and trends.',
      icon: Icons.insights_outlined,
      view: ResultsAnalyticsView.overview,
    ),
    _AnalysisItem(
      title: 'Subject Analysis',
      description: 'Inspect marks, pass rates, absences and subject results.',
      icon: Icons.menu_book_outlined,
      view: ResultsAnalyticsView.subject,
    ),
    _AnalysisItem(
      title: 'Student Performance',
      description: 'Track a student across published examinations.',
      icon: Icons.person_search_outlined,
      view: ResultsAnalyticsView.student,
    ),
    _AnalysisItem(
      title: 'Class Performance',
      description: 'Compare class statistics, subjects and rankings.',
      icon: Icons.groups_outlined,
      view: ResultsAnalyticsView.classPerformance,
    ),
    _AnalysisItem(
      title: 'Section Comparison',
      description: 'Compare all sections within the selected class.',
      icon: Icons.compare_arrows_outlined,
      view: ResultsAnalyticsView.sectionComparison,
    ),
    _AnalysisItem(
      title: 'Pass / Fail Analysis',
      description: 'Identify failures, absences and borderline students.',
      icon: Icons.rule_outlined,
      view: ResultsAnalyticsView.passFail,
    ),
    _AnalysisItem(
      title: 'Top & Weak Students',
      description: 'Support interventions using rank and risk indicators.',
      icon: Icons.trending_up_outlined,
      view: ResultsAnalyticsView.topAndWeak,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results Analysis')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1200
                ? 4
                : constraints.maxWidth >= 700
                ? 2
                : 1;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1450),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: columns == 1 ? 1.45 : 1.15,
                    ),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _AnalysisCard(item: item);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnalysisItem {
  const _AnalysisItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.view,
  });

  final String title;
  final String description;
  final IconData icon;
  final ResultsAnalyticsView view;
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.item});

  final _AnalysisItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ResultsAnalyticsPage(view: item.view),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: colors.onPrimaryContainer),
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.arrow_forward_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
