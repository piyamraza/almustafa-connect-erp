import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:almustafa_connect_erp/core/widgets/app_page_layout.dart';

import 'exams_page.dart';
import 'marks_entry_page.dart';
import 'result_summary_page.dart';
import 'annual_promotion_page.dart';
import 'question_paper_module_page.dart';

class ExaminationDashboardPage extends StatelessWidget {
  const ExaminationDashboardPage({super.key});

  static const List<_ExaminationModule> _modules = [
    _ExaminationModule(
      title: 'Question Papers',
      description:
          'Build a question bank and generate objective and subjective papers.',
      icon: Icons.quiz_outlined,
      isAvailable: true,
    ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppPageHeader(
                        title: 'Examination Workspace',
                        description:
                            'Prepare exams and papers, enter marks, review results and manage promotions.',
                        icon: Icons.fact_check_rounded,
                      ),
                      const SizedBox(height: 22),
                      GridView.builder(
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
                          return AppModuleCard(
                            title: module.title,
                            description: module.description,
                            icon: module.icon,
                            onTap: () => _openModule(context, module),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openModule(BuildContext context, _ExaminationModule module) {
    final page = switch (module.title) {
      'Exams' => const ExamsPage(),
      'Marks Entry' => const MarksEntryPage(),
      'Annual Promotion' => const AnnualPromotionPage(),
      'Question Papers' => const QuestionPaperModulePage(),
      _ => const ResultSummaryPage(),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
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
