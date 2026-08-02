import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import 'gazette_page.dart';
import 'merit_list_page.dart';
import 'published_results_page.dart';
import 'report_cards_page.dart';
import 'results_dashboard_page.dart';
import 'results_analysis_hub_page.dart';
import 'result_archive_page.dart';
import 'results_reports_page.dart';
import 'teacher_results_page.dart';

class ResultsModulePage extends StatelessWidget {
  const ResultsModulePage({super.key});

  static const List<_ResultsModuleItem> _items = [
    _ResultsModuleItem(
      title: 'Dashboard',
      description: 'View published-result statistics and recent results.',
      icon: Icons.dashboard_outlined,
    ),
    _ResultsModuleItem(
      title: 'Student Results',
      description: 'Search and open a student\'s published result.',
      icon: Icons.person_search_outlined,
    ),
    _ResultsModuleItem(
      title: 'Class Results',
      description: 'View complete published results for a class.',
      icon: Icons.groups_outlined,
    ),
    _ResultsModuleItem(
      title: 'Section Results',
      description: 'View published results for a selected section.',
      icon: Icons.group_work_outlined,
    ),
    _ResultsModuleItem(
      title: 'Teacher Results',
      description: 'View subject performance for a selected teacher.',
      icon: Icons.school_outlined,
    ),
    _ResultsModuleItem(
      title: 'Report Cards',
      description: 'Open professional individual student report cards.',
      icon: Icons.description_outlined,
    ),
    _ResultsModuleItem(
      title: 'Merit List',
      description: 'View top published performers by merit scope.',
      icon: Icons.emoji_events_outlined,
    ),
    _ResultsModuleItem(
      title: 'Gazette',
      description: 'View a professional published-results gazette.',
      icon: Icons.article_outlined,
    ),
    _ResultsModuleItem(
      title: 'Analysis',
      description:
          'Explore published-result statistics and performance insights.',
      icon: Icons.analytics_outlined,
    ),
    _ResultsModuleItem(
      title: 'Reports',
      description: 'Export published result reports in PDF or Excel format.',
      icon: Icons.assessment_outlined,
    ),
    _ResultsModuleItem(
      title: 'Archive',
      description: 'Search historical published and locked result records.',
      icon: Icons.inventory_2_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Results')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = _columnCount(constraints.maxWidth);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1500),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: _cardAspectRatio(
                        constraints.maxWidth,
                        columns,
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _ResultsModuleCard(
                        item: item,
                        onOpen: () => _openItem(context, index),
                      );
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

  int _columnCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 700) return 2;
    return 1;
  }

  double _cardAspectRatio(double width, int columns) {
    if (columns == 1) return 1.15;
    if (columns == 2) return 1.35;
    return width >= 1200 ? 1.18 : 1.25;
  }

  void _openItem(BuildContext context, int index) {
    final Widget? page = switch (index) {
      0 => const ResultsDashboardPage(),
      1 => const PublishedResultsPage(type: ResultsViewType.studentResults),
      2 => const PublishedResultsPage(type: ResultsViewType.classResults),
      3 => const PublishedResultsPage(type: ResultsViewType.sectionResults),
      4 => const TeacherResultsPage(),
      5 => const ReportCardsPage(),
      6 => const MeritListPage(),
      7 => const GazettePage(),
      8 => const ResultsAnalysisHubPage(),
      9 => const ResultsReportsPage(),
      10 => const ResultArchivePage(),
      _ => null,
    };
    if (page == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _ResultsModuleItem {
  const _ResultsModuleItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _ResultsModuleCard extends StatelessWidget {
  const _ResultsModuleCard({required this.item, required this.onOpen});

  final _ResultsModuleItem item;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: colors.onPrimaryContainer),
              ),
              const SizedBox(height: 20),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onOpen,
                  child: const Text('Open'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
