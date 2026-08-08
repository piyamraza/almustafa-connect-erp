import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import 'exams_page.dart';
import 'marks_entry_page.dart';
import 'result_summary_page.dart';
import 'annual_promotion_page.dart';

class ExaminationDashboardPage extends StatelessWidget {
  const ExaminationDashboardPage({super.key});

  static const List<_ExaminationModule> _modules = [
    _ExaminationModule(
      title: 'Exams',
      description: 'Create and manage examination schedules.',
      icon: Icons.assignment_outlined,
      isAvailable: true,
    ),
    _ExaminationModule(
      title: 'Marks Entry',
      description: 'Enter and review student marks.',
      icon: Icons.edit_note_outlined,
      isAvailable: true,
    ),
    _ExaminationModule(
      title: 'Result Review',
      description: 'Calculate, review and publish examination results.',
      icon: Icons.emoji_events_outlined,
      isAvailable: true,
    ),
    _ExaminationModule(
      title: 'Annual Promotion',
      description: 'Review final results and safely promote students.',
      icon: Icons.school_outlined,
      isAvailable: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: const Text('Examination'),
      ),
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
                    itemCount: _modules.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: _cardAspectRatio(
                        width: constraints.maxWidth,
                        columns: columns,
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final module = _modules[index];
                      return _ExaminationModuleCard(
                        module: module,
                        onOpen: module.isAvailable
                            ? () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) {
                                    if (module.title == 'Exams') {
                                      return const ExamsPage();
                                    }
                                    if (module.title == 'Marks Entry') {
                                      return const MarksEntryPage();
                                    }
                                    if (module.title == 'Annual Promotion') {
                                      return const AnnualPromotionPage();
                                    }
                                    return const ResultSummaryPage();
                                  },
                                ),
                              )
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
    if (width >= 1200) {
      return 5;
    }
    if (width >= 840) {
      return 3;
    }
    if (width >= 560) {
      return 2;
    }
    return 1;
  }

  double _cardAspectRatio({required double width, required int columns}) {
    if (columns == 1) {
      return 1.55;
    }
    if (columns == 2) {
      return 1.28;
    }
    return width >= 1200 ? 1.12 : 1.2;
  }
}

class _ExaminationModule {
  const _ExaminationModule({
    required this.title,
    required this.description,
    required this.icon,
    this.isAvailable = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isAvailable;
}

class _ExaminationModuleCard extends StatelessWidget {
  const _ExaminationModuleCard({required this.module, required this.onOpen});

  final _ExaminationModule module;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isAvailable = module.isAvailable;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? colors.primaryContainer
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      module.icon,
                      color: isAvailable
                          ? colors.onPrimaryContainer
                          : colors.onSurfaceVariant,
                    ),
                  ),
                  if (!isAvailable)
                    Chip(
                      label: const Text('Coming Soon'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: colors.secondaryContainer,
                      labelStyle: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                module.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                module.description,
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
                  child: Text(isAvailable ? 'Open' : 'Coming Soon'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
