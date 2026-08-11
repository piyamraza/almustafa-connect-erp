import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../../domain/entities/parent_communication_dashboard_entity.dart';
import '../../domain/services/parent_communication_service.dart';
import '../bloc/parent_communication_bloc.dart';

class ParentNoticesPage extends StatelessWidget {
  const ParentNoticesPage({
    super.key,
    required this.parent,
    required this.student,
  });

  final ParentAccountEntity parent;
  final StudentEntity student;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ParentCommunicationBloc(sl<ParentCommunicationService>())..add(
            LoadParentCommunicationDashboard(
              parent: parent,
              student: student,
              academicSession: '2026-2027',
            ),
          ),
      child: _ParentNoticesView(parent: parent, student: student),
    );
  }
}

class _ParentNoticesView extends StatefulWidget {
  const _ParentNoticesView({required this.parent, required this.student});

  final ParentAccountEntity parent;
  final StudentEntity student;

  @override
  State<_ParentNoticesView> createState() => _ParentNoticesViewState();
}

class _ParentNoticesViewState extends State<_ParentNoticesView> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.fullName} Notices'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocBuilder<ParentCommunicationBloc, ParentCommunicationState>(
        builder: (context, state) {
          if (state is ParentCommunicationLoading ||
              state is ParentCommunicationInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ParentCommunicationError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 54),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _reload(context),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final dashboard = (state as ParentCommunicationLoaded).dashboard;
          final notices = _filtered(dashboard.notices);

          return RefreshIndicator(
            onRefresh: () async => _reload(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _NoticeSummary(dashboard: dashboard),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _filter,
                  decoration: const InputDecoration(
                    labelText: 'Filter Notices',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Notices')),
                    DropdownMenuItem(value: 'unread', child: Text('Unread')),
                    DropdownMenuItem(value: 'read', child: Text('Read')),
                    DropdownMenuItem(
                      value: 'important',
                      child: Text('Important / Urgent'),
                    ),
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Pending Acknowledgement'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _filter = value ?? 'all');
                  },
                ),
                const SizedBox(height: 16),
                if (notices.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No notices match the selected filter.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...notices.map(
                    (notice) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NoticeCard(
                        item: notice,
                        onRead: () {
                          context.read<ParentCommunicationBloc>().add(
                            ReadParentNotice(
                              parent: widget.parent,
                              student: widget.student,
                              academicSession: '2026-2027',
                              noticeId: notice.id,
                            ),
                          );
                        },
                        onAcknowledge: () {
                          context.read<ParentCommunicationBloc>().add(
                            AcknowledgeParentNotice(
                              parent: widget.parent,
                              student: widget.student,
                              academicSession: '2026-2027',
                              noticeId: notice.id,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _reload(BuildContext context) {
    context.read<ParentCommunicationBloc>().add(
      LoadParentCommunicationDashboard(
        parent: widget.parent,
        student: widget.student,
        academicSession: '2026-2027',
      ),
    );
  }

  List<ParentNoticeItemEntity> _filtered(List<ParentNoticeItemEntity> values) {
    return values
        .where((item) {
          return switch (_filter) {
            'unread' => !item.isRead,
            'read' => item.isRead,
            'important' => [
              'important',
              'urgent',
              'emergency',
            ].contains(item.priority.toLowerCase()),
            'pending' => item.acknowledgementRequired && !item.isAcknowledged,
            _ => true,
          };
        })
        .toList(growable: false);
  }
}

class _NoticeSummary extends StatelessWidget {
  const _NoticeSummary({required this.dashboard});

  final ParentCommunicationDashboardEntity dashboard;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total', dashboard.notices.length, Icons.campaign_outlined),
      ('Unread', dashboard.unreadNoticeCount, Icons.mark_email_unread_outlined),
      (
        'Pending Ack.',
        dashboard.pendingAcknowledgementCount,
        Icons.pending_actions_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 1 ? 3.4 : 1.8,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(item.$3),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.$2}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(item.$1),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.item,
    required this.onRead,
    required this.onAcknowledge,
  });

  final ParentNoticeItemEntity item;
  final VoidCallback onRead;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final priority = item.priority.toLowerCase();
    final icon = switch (priority) {
      'emergency' => Icons.crisis_alert_outlined,
      'urgent' => Icons.warning_amber_outlined,
      'important' => Icons.priority_high_outlined,
      _ => Icons.campaign_outlined,
    };

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${item.priority.toUpperCase()}'
          '${item.publishAt == null ? '' : ' | ${_date(item.publishAt!)}'}',
        ),
        trailing: Icon(
          item.isRead
              ? Icons.mark_email_read_outlined
              : Icons.mark_email_unread_outlined,
        ),
        onExpansionChanged: (expanded) {
          if (expanded && !item.isRead) onRead();
        },
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(alignment: Alignment.centerLeft, child: Text(item.message)),
          if (item.attachmentUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Attachments: ${item.attachmentUrls.length}'),
            ),
          ],
          if (item.acknowledgementRequired) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: item.isAcknowledged
                  ? const Chip(
                      avatar: Icon(Icons.check_circle_outline),
                      label: Text('Acknowledged'),
                    )
                  : FilledButton.icon(
                      onPressed: onAcknowledge,
                      icon: const Icon(Icons.done_all),
                      label: const Text('Acknowledge'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
