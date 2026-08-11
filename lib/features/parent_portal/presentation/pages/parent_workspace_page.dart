import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../../core/di/service_locator.dart';
import '../../../authentication/domain/usecases/logout_usecase.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../../domain/services/parent_context_service.dart';
import '../widgets/parent_portal_access_gate.dart';
import 'parent_academic_dashboard_page.dart';
import 'parent_attendance_page.dart';
import 'parent_chat_page.dart';
import 'parent_communication_dashboard_page.dart';
import 'parent_fee_page.dart';
import 'parent_homework_page.dart';
import 'parent_notices_page.dart';
import 'parent_notification_center_page.dart';
import 'parent_results_page.dart';

class ParentWorkspacePage extends StatelessWidget {
  const ParentWorkspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ParentPortalAccessGate(
      builder: (context, parentContext) {
        final parent = parentContext.currentParent!;
        final student = parentContext.currentStudent!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Parent Portal'),
            actions: [
              const DashboardNavigationButton(),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => _open(
                  context,
                  ParentNotificationCenterPage(
                    parent: parent,
                    studentId: student.id,
                  ),
                ),
                icon: const Icon(Icons.notifications_outlined),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () {
                  parentContext.loadCurrentParent(forceRefresh: true);
                },
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Logout',
                onPressed: () => _logout(context, parentContext),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () =>
                parentContext.loadCurrentParent(forceRefresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                _ParentHeader(
                  parent: parent,
                  student: student,
                  parentContext: parentContext,
                ),
                const SizedBox(height: 18),
                Text(
                  'Student Overview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _StudentCard(student: student),
                const SizedBox(height: 20),
                Text(
                  'Parent Services',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _ServiceGrid(parent: parent, student: student),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _open(BuildContext context, Widget page) {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _logout(
    BuildContext context,
    ParentContextService parentContext,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !context.mounted) return;

    await parentContext.clear();
    await sl<LogoutUseCase>()();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}

class _ParentHeader extends StatelessWidget {
  const _ParentHeader({
    required this.parent,
    required this.student,
    required this.parentContext,
  });

  final ParentAccountEntity parent;
  final StudentEntity student;
  final ParentContextService parentContext;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 20,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const CircleAvatar(
              radius: 32,
              child: Icon(Icons.family_restroom, size: 32),
            ),
            SizedBox(
              width: 310,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parent.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    parent.mobileNumber.trim().isEmpty
                        ? 'Parent Account'
                        : parent.mobileNumber,
                  ),
                ],
              ),
            ),
            if (parentContext.linkedStudents.length > 1)
              SizedBox(
                width: 290,
                child: DropdownButtonFormField<String>(
                  initialValue: student.id,
                  decoration: const InputDecoration(
                    labelText: 'Select Child',
                    border: OutlineInputBorder(),
                  ),
                  items: parentContext.linkedStudents
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.fullName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      parentContext.selectStudent(value);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.parent, required this.student});

  final ParentAccountEntity parent;
  final StudentEntity student;

  @override
  Widget build(BuildContext context) {
    final services = <_ServiceItem>[
      _ServiceItem(
        title: 'Academic Dashboard',
        subtitle: 'Complete academic overview',
        icon: Icons.school_outlined,
        page: ParentAcademicDashboardPage(student: student),
      ),
      _ServiceItem(
        title: 'Attendance',
        subtitle: 'Monthly attendance record',
        icon: Icons.fact_check_outlined,
        page: ParentAttendancePage(student: student),
      ),
      _ServiceItem(
        title: 'Homework',
        subtitle: 'Published and upcoming homework',
        icon: Icons.menu_book_outlined,
        page: ParentHomeworkPage(student: student),
      ),
      _ServiceItem(
        title: 'Exam Results',
        subtitle: 'Results and subject performance',
        icon: Icons.assessment_outlined,
        page: ParentResultsPage(student: student),
      ),
      _ServiceItem(
        title: 'Fee Status',
        subtitle: 'Paid and pending monthly fees',
        icon: Icons.payments_outlined,
        page: ParentFeePage(student: student),
      ),
      _ServiceItem(
        title: 'Notices',
        subtitle: 'School notices and circulars',
        icon: Icons.campaign_outlined,
        page: ParentNoticesPage(parent: parent, student: student),
      ),
      _ServiceItem(
        title: 'Communication',
        subtitle: 'School communication centre',
        icon: Icons.forum_outlined,
        page: ParentCommunicationDashboardPage(
          parent: parent,
          student: student,
        ),
      ),
      _ServiceItem(
        title: 'Messages',
        subtitle: 'Parent-teacher conversations',
        icon: Icons.chat_bubble_outline,
        page: ParentChatPage(parent: parent, student: student),
      ),
      _ServiceItem(
        title: 'Notifications',
        subtitle: 'Alerts and unread updates',
        icon: Icons.notifications_outlined,
        page: ParentNotificationCenterPage(
          parent: parent,
          studentId: student.id,
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 700
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: columns == 1 ? 3.4 : 2.35,
          ),
          itemBuilder: (context, index) {
            final item = services[index];

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(builder: (_) => item.page),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 25, child: Icon(item.icon)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ServiceItem {
  const _ServiceItem({
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

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});

  final StudentEntity student;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 24,
          runSpacing: 14,
          children: [
            _Info(label: 'Student', value: student.fullName),
            _Info(label: 'Admission No.', value: student.admissionNo),
            _Info(label: 'Roll No.', value: student.rollNumber),
            _Info(label: 'Class', value: student.classId),
            _Info(label: 'Section', value: student.sectionId),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
