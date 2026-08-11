import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../../core/widgets/app_page_layout.dart';
import 'published_results_page.dart';
import 'report_cards_page.dart';
import 'result_archive_page.dart';
import 'results_analysis_hub_page.dart';
import 'results_dashboard_page.dart';
import 'results_reports_page.dart';
import 'teacher_results_page.dart';

class ResultsModulePage extends StatelessWidget {
  const ResultsModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_ResultAction>[
      _ResultAction(
        'Results Dashboard',
        'Published result statistics and recent activity',
        Icons.dashboard_rounded,
        const Color(0xFF246BFD),
        const ResultsDashboardPage(),
      ),
      _ResultAction(
        'Student Results',
        'Search and open an individual published result',
        Icons.person_search_rounded,
        const Color(0xFF06A7C6),
        const PublishedResultsPage(type: ResultsViewType.studentResults),
      ),
      _ResultAction(
        'Class Results',
        'View complete published results class-wise',
        Icons.groups_rounded,
        const Color(0xFF0AA47A),
        const PublishedResultsPage(type: ResultsViewType.classResults),
      ),
      _ResultAction(
        'Section Results',
        'Review published performance for a section',
        Icons.view_module_rounded,
        const Color(0xFF8B5CF6),
        const PublishedResultsPage(type: ResultsViewType.sectionResults),
      ),
      _ResultAction(
        'Teacher Results',
        'Subject performance for selected teachers',
        Icons.school_rounded,
        const Color(0xFFF59E0B),
        const TeacherResultsPage(),
      ),
      _ResultAction(
        'Report Cards',
        'Professional individual student report cards',
        Icons.description_rounded,
        const Color(0xFFEC4899),
        const ReportCardsPage(),
      ),
      _ResultAction(
        'Performance Analysis',
        'Explore result trends and academic insights',
        Icons.analytics_rounded,
        const Color(0xFF6366F1),
        const ResultsAnalysisHubPage(),
      ),
      _ResultAction(
        'Result Reports',
        'Export published reports in PDF or Excel',
        Icons.assessment_rounded,
        const Color(0xFFEF6C45),
        const ResultsReportsPage(),
      ),
      _ResultAction(
        'Result Archive',
        'Search historical published and locked records',
        Icons.inventory_2_rounded,
        const Color(0xFF64748B),
        const ResultArchivePage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        actions: const [DashboardNavigationButton()],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1320
                ? 5
                : constraints.maxWidth >= 980
                ? 4
                : constraints.maxWidth >= 680
                ? 2
                : 1;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ResultsHero(),
                      const SizedBox(height: 22),
                      const Text(
                        'Result Operations',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF14213D),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Review, publish and analyse academic performance.',
                        style: TextStyle(color: Colors.blueGrey.shade600),
                      ),
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          mainAxisExtent: constraints.maxWidth < 680
                              ? 128
                              : 188,
                        ),
                        itemBuilder: (_, index) =>
                            _ResultActionCard(action: items[index]),
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
}

class _ResultsHero extends StatelessWidget {
  const _ResultsHero();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 600) {
      return const AppModuleHero(
        title: 'Academic Results Center',
        description: 'Review and publish academic performance.',
        icon: Icons.fact_check_rounded,
        decorativeIcon: Icons.auto_graph_rounded,
        colors: [Color(0xFF2878FF), Color(0xFF1646A8)],
      );
    }
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 27),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF153E91)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x302563EB),
            blurRadius: 26,
            offset: Offset(0, 11),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .22)),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Academic Results Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Turn marks into clear, reliable academic insights.',
                  style: TextStyle(color: Color(0xFFE8F1FF), fontSize: 15),
                ),
              ],
            ),
          ),
          Icon(
            Icons.auto_graph_rounded,
            size: 102,
            color: Colors.white.withValues(alpha: .09),
          ),
        ],
      ),
    );
  }
}

class _ResultAction {
  const _ResultAction(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.page,
  );

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;
}

class _ResultActionCard extends StatefulWidget {
  const _ResultActionCard({required this.action});

  final _ResultAction action;

  @override
  State<_ResultActionCard> createState() => _ResultActionCardState();
}

class _ResultActionCardState extends State<_ResultActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: action.color.withValues(alpha: _hovered ? .42 : .2),
          ),
          boxShadow: [
            BoxShadow(
              color: action.color.withValues(alpha: _hovered ? .17 : .08),
              blurRadius: _hovered ? 24 : 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(21),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => action.page)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: action.color.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(action.icon, color: action.color, size: 27),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_outward_rounded, color: action.color),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14213D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.blueGrey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
