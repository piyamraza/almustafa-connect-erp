import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../../domain/entities/parent_communication_dashboard_entity.dart';
import '../bloc/parent_communication_bloc.dart';

class ParentCommunicationDashboardPage extends StatelessWidget {
  const ParentCommunicationDashboardPage({
    super.key,
    required this.parent,
    required this.student,
    this.academicSession = '2026-2027',
  });

  final ParentAccountEntity parent;
  final StudentEntity student;
  final String academicSession;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ParentCommunicationBloc>()
        ..add(
          LoadParentCommunicationDashboard(
            parent: parent,
            student: student,
            academicSession: academicSession,
          ),
        ),
      child: _View(
        parent: parent,
        student: student,
        academicSession: academicSession,
      ),
    );
  }
}

class _View extends StatelessWidget {
  const _View({
    required this.parent,
    required this.student,
    required this.academicSession,
  });

  final ParentAccountEntity parent;
  final StudentEntity student;
  final String academicSession;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: Text('${student.fullName} - Fees & Communication')),
      body: BlocBuilder<ParentCommunicationBloc, ParentCommunicationState>(
        builder: (context, state) {
          return switch (state) {
            ParentCommunicationInitial() || ParentCommunicationLoading() =>
              const Center(child: CircularProgressIndicator()),
            ParentCommunicationError(:final message) => Center(
              child: Text(message),
            ),
            ParentCommunicationLoaded(:final dashboard) => _Content(
              parent: parent,
              student: student,
              academicSession: academicSession,
              dashboard: dashboard,
            ),
          };
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.parent,
    required this.student,
    required this.academicSession,
    required this.dashboard,
  });

  final ParentAccountEntity parent;
  final StudentEntity student;
  final String academicSession;
  final ParentCommunicationDashboardEntity dashboard;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Summary(
                  label: 'Outstanding',
                  value: 'Rs. ${dashboard.totalOutstanding.toStringAsFixed(0)}',
                  icon: Icons.payments_outlined,
                ),
                _Summary(
                  label: 'Unpaid Months',
                  value: '${dashboard.unpaidCount}',
                  icon: Icons.warning_amber_outlined,
                ),
                _Summary(
                  label: 'Unread Notices',
                  value: '${dashboard.unreadNoticeCount}',
                  icon: Icons.mark_email_unread_outlined,
                ),
                _Summary(
                  label: 'Pending Ack.',
                  value: '${dashboard.pendingAcknowledgementCount}',
                  icon: Icons.verified_outlined,
                ),
                _Summary(
                  label: 'Upcoming Events',
                  value: '${dashboard.upcomingEventCount}',
                  icon: Icons.event_outlined,
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Fees'),
              Tab(text: 'Notices'),
              Tab(text: 'Calendar'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _FeeList(items: dashboard.fees),
                _NoticeList(
                  parent: parent,
                  student: student,
                  academicSession: academicSession,
                  items: dashboard.notices,
                ),
                _CalendarList(items: dashboard.calendarItems),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(label),
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

class _FeeList extends StatelessWidget {
  const _FeeList({required this.items});

  final List<ParentFeeItemEntity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No fee records found.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final item in items)
          Card(
            child: ListTile(
              title: Text(
                item.month.isEmpty
                    ? item.title
                    : '${item.title} - ${item.month}',
              ),
              subtitle: Text(
                'Amount: Rs. ${item.amount.toStringAsFixed(0)} • '
                'Paid: Rs. ${item.paidAmount.toStringAsFixed(0)} • '
                'Outstanding: Rs. ${item.outstanding.toStringAsFixed(0)}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  Chip(label: Text(item.status)),
                  if (item.challanUrl.isNotEmpty)
                    IconButton(
                      tooltip: 'Open Challan',
                      onPressed: () => _open(item.challanUrl),
                      icon: const Icon(Icons.receipt_long_outlined),
                    ),
                  if (item.receiptUrl.isNotEmpty)
                    IconButton(
                      tooltip: 'Open Receipt',
                      onPressed: () => _open(item.receiptUrl),
                      icon: const Icon(Icons.download_done_outlined),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri);
  }
}

class _NoticeList extends StatelessWidget {
  const _NoticeList({
    required this.parent,
    required this.student,
    required this.academicSession,
    required this.items,
  });

  final ParentAccountEntity parent;
  final StudentEntity student;
  final String academicSession;
  final List<ParentNoticeItemEntity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No active notices found.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final item in items)
          Card(
            child: ExpansionTile(
              onExpansionChanged: (expanded) {
                if (expanded && !item.isRead) {
                  context.read<ParentCommunicationBloc>().add(
                    ReadParentNotice(
                      parent: parent,
                      student: student,
                      academicSession: academicSession,
                      noticeId: item.id,
                    ),
                  );
                }
              },
              leading: Icon(
                item.isRead
                    ? Icons.mark_email_read_outlined
                    : Icons.mark_email_unread_outlined,
              ),
              title: Text(item.title),
              subtitle: Text(item.priority.toUpperCase()),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(item.message),
                  ),
                ),
                for (final url in item.attachmentUrls)
                  ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: const Text('Open Attachment'),
                    onTap: () async {
                      final uri = Uri.tryParse(url);
                      if (uri != null) await launchUrl(uri);
                    },
                  ),
                if (item.acknowledgementRequired)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: item.isAcknowledged
                            ? null
                            : () {
                                context.read<ParentCommunicationBloc>().add(
                                  AcknowledgeParentNotice(
                                    parent: parent,
                                    student: student,
                                    academicSession: academicSession,
                                    noticeId: item.id,
                                  ),
                                );
                              },
                        icon: const Icon(Icons.verified_outlined),
                        label: Text(
                          item.isAcknowledged
                              ? 'Acknowledged'
                              : 'I Have Read This Notice',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CalendarList extends StatelessWidget {
  const _CalendarList({required this.items});

  final List<ParentCalendarItemEntity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No calendar events found.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final item in items)
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.event_outlined)),
              title: Text(item.title),
              subtitle: Text(
                [
                  item.type,
                  if (item.startDate != null) _date(item.startDate!),
                  item.description,
                ].where((value) => value.isNotEmpty).join(' • '),
              ),
            ),
          ),
      ],
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
