import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../accounts/presentation/pages/accounts_dashboard_page.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../communication/presentation/pages/communication_dashboard_page.dart';
import '../../../exams/presentation/pages/examination_dashboard_page.dart';
import '../../../fees/presentation/pages/fee_management_dashboard_page.dart';
import '../../../homework/presentation/pages/homework_dashboard_page.dart';
import '../../../results/presentation/pages/results_module_page.dart';
import '../../../school_store/presentation/pages/school_store_dashboard_page.dart';
import 'graphs_report_page.dart';

class ReportsDashboardPage extends StatelessWidget {
  const ReportsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = <_ReportCardData>[
      _ReportCardData(
        title: 'Graphs',
        subtitle:
            'Enrollment, attendance, fees, gender and result distributions.',
        icon: Icons.pie_chart_rounded,
        page: const GraphsReportPage(),
      ),
      _ReportCardData(
        title: 'Student Attendance Reports',
        subtitle:
            'Daily attendance, history, student attendance and summaries.',
        icon: Icons.fact_check_outlined,
        page: const AttendancePage(),
      ),
      _ReportCardData(
        title: 'Fee Reports',
        subtitle: 'Fee collection, dues, defaulters and payment records.',
        icon: Icons.payments_outlined,
        page: const FeeManagementDashboardPage(),
      ),
      _ReportCardData(
        title: 'Examination Reports',
        subtitle: 'Exam setup, marks entry and examination summaries.',
        icon: Icons.quiz_outlined,
        page: const ExaminationDashboardPage(),
      ),
      _ReportCardData(
        title: 'Result Reports',
        subtitle: 'Student results, result analysis and result records.',
        icon: Icons.grade_outlined,
        page: const ResultsModulePage(),
      ),
      _ReportCardData(
        title: 'Homework Reports',
        subtitle: 'Homework activity, submissions and completion tracking.',
        icon: Icons.menu_book_outlined,
        page: const HomeworkDashboardPage(),
      ),
      _ReportCardData(
        title: 'Accounts Reports',
        subtitle: 'Income, expenses, cashbook and profit and loss reports.',
        icon: Icons.account_balance_outlined,
        page: const AccountsDashboardPage(),
      ),
      _ReportCardData(
        title: 'Communication Reports',
        subtitle:
            'Messages, delivery tracking, audit and communication analytics.',
        icon: Icons.campaign_outlined,
        page: const CommunicationDashboardPage(),
      ),
      _ReportCardData(
        title: 'School Store Reports',
        subtitle: 'Sales, purchases, stock, receivables, payables and profit.',
        icon: Icons.storefront_outlined,
        page: const SchoolStoreDashboardPage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: const [DashboardNavigationButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 3
              : constraints.maxWidth >= 700
              ? 2
              : 2;
          final width = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - ((columns - 1) * 16)) / columns;

          return SingleChildScrollView(
            padding: EdgeInsets.all(columns == 1 ? 10 : 20),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: reports
                  .map(
                    (report) => SizedBox(
                      width: width,
                      child: _ReportCard(data: report),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.data});
  final _ReportCardData data;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => data.page));
        },
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 18),
          child: compact
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(radius: 18, child: Icon(data.icon, size: 19)),
                    const SizedBox(height: 7),
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: compact ? 18 : 24,
                      child: Icon(data.icon, size: compact ? 19 : 24),
                    ),
                    SizedBox(width: compact ? 10 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: compact ? 2 : 6),
                          Text(
                            data.subtitle,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: compact ? 4 : 12),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Open',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ReportCardData {
  const _ReportCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;
}
