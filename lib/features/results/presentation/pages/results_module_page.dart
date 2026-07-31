import 'package:flutter/material.dart';

import 'gazette_page.dart';
import 'merit_list_page.dart';
import 'published_results_page.dart';
import 'report_cards_page.dart';
import 'results_dashboard_page.dart';
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
      description: 'Result analysis will be available in a later phase.',
      icon: Icons.analytics_outlined,
      isAvailable: false,
    ),
    _ResultsModuleItem(
      title: 'Reports',
      description: 'Exportable result reports will be available in a later phase.',
      icon: Icons.assessment_outlined,
      isAvailable: false,
    ),
    _ResultsModuleItem(
      title: 'Archive',
      description: 'Result archive will be available in a later phase.',
      icon: Icons.inventory_2_outlined,
      isAvailable: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
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
                        onOpen: item.isAvailable
                            ? () => _openItem(context, index)
                            : null,
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
      _ => null,
    };
    if (page == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}

class _ResultsModuleItem {
  const _ResultsModuleItem({
    required this.title,
    required this.description,
    required this.icon,
    this.isAvailable = true,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isAvailable;
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
                  color: item.isAvailable
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: item.isAvailable
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
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
                  child: Text(item.isAvailable ? 'Open' : 'Coming Soon'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
