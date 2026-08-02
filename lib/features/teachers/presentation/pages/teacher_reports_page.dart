import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../results/presentation/pages/teacher_results_page.dart';
import '../../../timetable/presentation/pages/teacher_workload_page.dart';
import 'teacher_attendance_report_page.dart';
import 'teacher_assignments_page.dart';

class TeacherReportsPage extends StatelessWidget {
  const TeacherReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = <_TeacherReportItem>[
      _TeacherReportItem(
        title: 'Teacher Workload Report',
        description:
            'Review assigned periods, free capacity, utilization and '
            'weekly teaching distribution.',
        icon: Icons.schedule_outlined,
        color: const Color(0xFF1565C0),
        page: const TeacherWorkloadPage(),
      ),
      _TeacherReportItem(
        title: 'Teacher Results Report',
        description:
            'Review subject-wise student performance, pass percentage '
            'and result distribution by teacher.',
        icon: Icons.school_outlined,
        color: const Color(0xFF7B1FA2),
        page: const TeacherResultsPage(),
      ),
      _TeacherReportItem(
        title: 'Teacher Attendance Report',
        description:
            'Review daily attendance, presence, absence and attendance '
            'history for teachers.',
        icon: Icons.fact_check_outlined,
        color: const Color(0xFF00897B),
        page: const TeacherAttendanceReportPage(),
      ),
      _TeacherReportItem(
        title: 'Academic Assignment Report',
        description:
            'Review class, section and subject assignments allocated '
            'to each teacher.',
        icon: Icons.assignment_ind_outlined,
        color: const Color(0xFFF57C00),
        page: const TeacherAssignmentsPage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: const Text('Teacher Reports'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1100
                ? 3
                : constraints.maxWidth >= 700
                ? 2
                : 1;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teacher Reports & Analytics',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Access consolidated teacher workload, academic '
                        'performance, attendance and assignment reports.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reports.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: columns == 1 ? 3.2 : 1.7,
                        ),
                        itemBuilder: (context, index) =>
                            _TeacherReportCard(item: reports[index]),
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

class _TeacherReportItem {
  const _TeacherReportItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.page,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget page;
}

class _TeacherReportCard extends StatelessWidget {
  const _TeacherReportCard({required this.item});

  final _TeacherReportItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(
            context,
          ).push<void>(MaterialPageRoute<void>(builder: (_) => item.page));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: item.color.withAlpha(28),
                child: Icon(item.icon, size: 19, color: item.color),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  item.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(builder: (_) => item.page),
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Report'),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
