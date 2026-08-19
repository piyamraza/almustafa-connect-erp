import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../../core/widgets/app_page_layout.dart';
import '../../../exams/domain/entities/exam_entity.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/domain/repositories/exam_repository.dart';
import '../../../exams/domain/repositories/exam_result_repository.dart';
import '../../../exams/domain/repositories/exam_subject_setup_repository.dart';
import 'published_results_page.dart';
import 'report_cards_page.dart';
import 'result_archive_page.dart';
import 'results_analysis_hub_page.dart';
import 'results_dashboard_page.dart';
import 'results_reports_page.dart';
import 'teacher_results_page.dart';
import 'student_development_profiles_page.dart';

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
        'Development Profiles',
        'Class-teacher ratings for student progress reports',
        Icons.stars_rounded,
        const Color(0xFF7C3AED),
        const StudentDevelopmentProfilesPage(),
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
                : 2;
            return SingleChildScrollView(
              padding: EdgeInsets.all(constraints.maxWidth < 680 ? 10 : 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ResultsHero(),
                      SizedBox(height: constraints.maxWidth < 680 ? 10 : 22),
                      const _ResultProgressOverview(),
                      SizedBox(height: constraints.maxWidth < 680 ? 12 : 22),
                      Text(
                        'Result Operations',
                        style: TextStyle(
                          fontSize: constraints.maxWidth < 680 ? 18 : 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF14213D),
                        ),
                      ),
                      SizedBox(height: constraints.maxWidth < 680 ? 2 : 5),
                      Text(
                        'Review, publish and analyse academic performance.',
                        style: TextStyle(color: Colors.blueGrey.shade600),
                      ),
                      SizedBox(height: constraints.maxWidth < 680 ? 8 : 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          mainAxisExtent: constraints.maxWidth < 680
                              ? 126
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

class _ResultProgressOverview extends StatefulWidget {
  const _ResultProgressOverview();

  @override
  State<_ResultProgressOverview> createState() =>
      _ResultProgressOverviewState();
}

class _ResultProgressOverviewState extends State<_ResultProgressOverview> {
  List<ExamEntity> _exams = const [];
  ExamEntity? _selectedExam;
  _ResultProgress? _progress;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      final exams = await sl<ExamRepository>().getExams();
      exams.sort((a, b) {
        final aDate = a.endDate ?? a.startDate ?? a.createdAt;
        final bDate = b.endDate ?? b.startDate ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
      if (!mounted) return;
      setState(() {
        _exams = exams;
        _selectedExam = exams.isEmpty ? null : exams.first;
        _loading = exams.isNotEmpty;
      });
      if (exams.isNotEmpty) {
        await _loadProgress(exams.first);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Result progress could not be loaded.';
      });
    }
  }

  Future<void> _loadProgress(ExamEntity exam) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        sl<ExamResultRepository>().getResultsForExam(exam.id),
        sl<ExamSubjectSetupRepository>().getSetupsForExam(exam.id),
      ]);
      final results = values[0] as List<ExamResultEntity>;
      final setups = values[1] as List<dynamic>;
      final studentGroups = <String, List<ExamResultEntity>>{};
      final subjectGroups = <String, List<ExamResultEntity>>{};

      for (final result in results) {
        studentGroups.putIfAbsent(result.studentId, () => []).add(result);
        for (final subject in result.subjectResults) {
          final id = subject.subjectId.trim();
          final key = id.isNotEmpty
              ? id
              : subject.subjectName.trim().toLowerCase();
          if (key.isNotEmpty) {
            subjectGroups.putIfAbsent(key, () => []).add(result);
          }
        }
      }

      final configuredSubjects = setups
          .map((setup) {
            final id = setup.subjectId.toString().trim();
            return id.isNotEmpty
                ? id
                : setup.subjectName.toString().trim().toLowerCase();
          })
          .where((key) => key.isNotEmpty)
          .toSet();
      final allSubjects = {...configuredSubjects, ...subjectGroups.keys};
      final finalSubjects = allSubjects.where((key) {
        final records = subjectGroups[key] ?? const <ExamResultEntity>[];
        return records.isNotEmpty &&
            records.every((result) => result.isPublished);
      }).length;

      if (!mounted || _selectedExam?.id != exam.id) return;
      setState(() {
        _progress = _ResultProgress(
          totalStudents: studentGroups.length,
          finalStudents: studentGroups.values
              .where(
                (records) =>
                    records.isNotEmpty &&
                    records.every((item) => item.isPublished),
              )
              .length,
          totalSubjects: allSubjects.length,
          finalSubjects: finalSubjects,
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted || _selectedExam?.id != exam.id) return;
      setState(() {
        _loading = false;
        _error = 'Result progress could not be loaded.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE6F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F163A70),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Result Finalization Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14213D),
                  ),
                ),
              ),
              if (_exams.isNotEmpty)
                SizedBox(
                  width: 230,
                  child: DropdownButtonFormField<ExamEntity>(
                    initialValue: _selectedExam,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Exam',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: _exams
                        .map(
                          (exam) => DropdownMenuItem(
                            value: exam,
                            child: Text(
                              exam.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (exam) {
                      if (exam == null || exam.id == _selectedExam?.id) return;
                      setState(() => _selectedExam = exam);
                      _loadProgress(exam);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SizedBox(height: 100, child: Center(child: Text(_error!)))
          else if (_selectedExam == null)
            const SizedBox(
              height: 100,
              child: Center(child: Text('No exam is available yet.')),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _ProgressDonut(
                    title: 'Student Result Progress',
                    totalLabel: 'Students who took exam',
                    total: progress?.totalStudents ?? 0,
                    finalCount: progress?.finalStudents ?? 0,
                    color: const Color(0xFF246BFD),
                    icon: Icons.groups_rounded,
                  ),
                  _ProgressDonut(
                    title: 'Subject Result Progress',
                    totalLabel: 'Total subjects',
                    total: progress?.totalSubjects ?? 0,
                    finalCount: progress?.finalSubjects ?? 0,
                    color: const Color(0xFF0AA47A),
                    icon: Icons.menu_book_rounded,
                  ),
                ];
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: [
                      cards.first,
                      const SizedBox(height: 12),
                      cards.last,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cards.first),
                    const SizedBox(width: 14),
                    Expanded(child: cards.last),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ProgressDonut extends StatelessWidget {
  const _ProgressDonut({
    required this.title,
    required this.totalLabel,
    required this.total,
    required this.finalCount,
    required this.color,
    required this.icon,
  });

  final String title;
  final String totalLabel;
  final int total;
  final int finalCount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final pending = (total - finalCount).clamp(0, total);
    final percentage = total == 0 ? 0 : ((finalCount / total) * 100).round();
    return Container(
      height: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 43,
                    sectionsSpace: 3,
                    startDegreeOffset: -90,
                    sections: total == 0
                        ? [
                            PieChartSectionData(
                              value: 1,
                              color: const Color(0xFFE2E8F0),
                              radius: 17,
                              showTitle: false,
                            ),
                          ]
                        : [
                            PieChartSectionData(
                              value: finalCount.toDouble(),
                              color: color,
                              radius: 17,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: pending.toDouble(),
                              color: const Color(0xFFF5A623),
                              radius: 17,
                              showTitle: false,
                            ),
                          ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text('Final', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 5),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14213D),
                  ),
                ),
                const SizedBox(height: 8),
                Text('$totalLabel: $total'),
                Text('Final: $finalCount', style: TextStyle(color: color)),
                Text(
                  'Pending: $pending',
                  style: const TextStyle(color: Color(0xFFD97706)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultProgress {
  const _ResultProgress({
    required this.totalStudents,
    required this.finalStudents,
    required this.totalSubjects,
    required this.finalSubjects,
  });

  final int totalStudents;
  final int finalStudents;
  final int totalSubjects;
  final int finalSubjects;
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
    final compact = MediaQuery.sizeOf(context).width < 680;
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
              padding: EdgeInsets.all(compact ? 10 : 18),
              child: compact
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: action.color.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            action.icon,
                            color: action.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          action.title,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF14213D),
                          ),
                        ),
                      ],
                    )
                  : Column(
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
                              child: Icon(
                                action.icon,
                                color: action.color,
                                size: 27,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_outward_rounded,
                              color: action.color,
                            ),
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
