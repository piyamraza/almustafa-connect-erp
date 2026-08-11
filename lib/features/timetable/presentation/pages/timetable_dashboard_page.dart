import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import 'auto_timetable_generator_page.dart';
import 'class_timetable_page.dart';
import 'teacher_workload_page.dart';
import 'manual_timetable_editor_page.dart';
import 'teacher_availability_page.dart';
import 'teacher_timetable_page.dart';
import 'day_timetable_page.dart';
import 'timetable_versioning_page.dart';
import 'timetable_reports_page.dart';
import 'timetable_configuration_page.dart';

class TimetableDashboardPage extends StatelessWidget {
  const TimetableDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = <_TimetableFeature>[
      _TimetableFeature(
        title: 'Teacher Availability',
        description:
            'Configure weekly off days, unavailable periods and workload limits.',
        icon: Icons.event_busy_outlined,
        color: const Color(0xFFC62828),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TeacherAvailabilityPage(),
            ),
          );
        },
      ),
      _TimetableFeature(
        title: 'Timetable Versioning',
        description: 'Create, publish, archive and restore timetable versions.',
        icon: Icons.history_outlined,
        color: const Color(0xFF6D4C41),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TimetableVersioningPage(),
            ),
          );
        },
      ),
      _TimetableFeature(
        title: 'Manual Timetable Editor',
        description:
            'Drag, swap, edit and validate timetable periods manually.',
        icon: Icons.edit_calendar_outlined,
        color: const Color(0xFF5E35B1),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ManualTimetableEditorPage(),
            ),
          );
        },
      ),
      _TimetableFeature(
        title: 'Auto Timetable Generator',
        description:
            'Generate a conflict-free timetable from current assignments.',
        icon: Icons.auto_awesome,
        color: const Color(0xFFD81B60),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AutoTimetableGeneratorPage(),
            ),
          );
        },
      ),
      _TimetableFeature(
        title: 'Timetable Configuration',
        description:
            'Set working days, school timings, assembly, break and periods.',
        icon: Icons.settings_suggest_outlined,
        color: const Color(0xFF3F51B5),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TimetableConfigurationPage(),
            ),
          );
        },
      ),
      _TimetableFeature(
        title: 'Class Timetable',
        description: 'Create and manage class and section timetables.',
        icon: Icons.view_week_outlined,
        color: const Color(0xFF00897B),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ClassTimetablePage()),
          );
        },
      ),
      _TimetableFeature(
        title: 'Teacher Timetable',
        description: 'View each teacher\'s weekly teaching schedule.',
        icon: Icons.co_present_outlined,
        color: const Color(0xFF7E57C2),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TeacherTimetablePage(),
            ),
          );
        },
      ),
      _TimetableFeature(
        title: 'Day-wise Timetable',
        description: 'Review the complete timetable for a selected day.',
        icon: Icons.calendar_view_day_outlined,
        color: const Color(0xFF039BE5),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DayTimetablePage()),
          );
        },
      ),
      _TimetableFeature(
        title: 'Teacher Workload',
        description: 'Monitor assigned periods and teacher workload.',
        icon: Icons.monitor_heart_outlined,
        color: const Color(0xFFF57C00),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TeacherWorkloadPage(),
            ),
          );
        },
      ),
      _TimetableFeature(
        title: 'Timetable Reports',
        description: 'Generate printable timetable and workload reports.',
        icon: Icons.summarize_outlined,
        color: const Color(0xFF546E7A),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TimetableReportsPage(),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: const Text('Timetable Management'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1350
                ? 5
                : constraints.maxWidth >= 1050
                ? 4
                : constraints.maxWidth >= 780
                ? 3
                : constraints.maxWidth >= 560
                ? 2
                : 1;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timetable',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configure school timings and manage academic schedules.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: features.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: columns == 1 ? 150 : null,
                          childAspectRatio: switch (columns) {
                            5 => 1.55,
                            4 => 1.8,
                            3 => 2.0,
                            2 => 2.2,
                            _ => 3.0,
                          },
                        ),
                        itemBuilder: (context, index) =>
                            _TimetableFeatureCard(feature: features[index]),
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

class _TimetableFeature {
  const _TimetableFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

class _TimetableFeatureCard extends StatelessWidget {
  const _TimetableFeatureCard({required this.feature});

  final _TimetableFeature feature;

  @override
  Widget build(BuildContext context) {
    final isAvailable = feature.onTap != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isAvailable ? 2 : 0,
      child: InkWell(
        onTap: feature.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: feature.color.withAlpha(31),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(feature.icon, size: 19, color: feature.color),
                  ),
                  const Spacer(),
                  if (!isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Coming Soon',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                feature.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                feature.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (isAvailable) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Open',
                      style: TextStyle(
                        color: feature.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: feature.color,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
