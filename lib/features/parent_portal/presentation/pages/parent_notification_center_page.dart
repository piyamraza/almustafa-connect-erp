import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../../domain/entities/parent_notification_entity.dart';
import '../bloc/parent_notification_bloc.dart';

class ParentNotificationCenterPage extends StatelessWidget {
  const ParentNotificationCenterPage({
    super.key,
    required this.parent,
    this.studentId,
  });

  final ParentAccountEntity parent;
  final String? studentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ParentNotificationBloc>()
        ..add(
          LoadParentNotifications(parentId: parent.id, studentId: studentId),
        ),
      child: _View(parent: parent, studentId: studentId),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this.parent, required this.studentId});

  final ParentAccountEntity parent;
  final String? studentId;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  ParentNotificationType? _type;
  bool? _isRead;

  void _load() {
    context.read<ParentNotificationBloc>().add(
      LoadParentNotifications(
        parentId: widget.parent.id,
        studentId: widget.studentId,
        type: _type,
        isRead: _isRead,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<ParentNotificationBloc>().add(
                MarkAllParentNotificationsRead(
                  parentId: widget.parent.id,
                  studentId: widget.studentId,
                ),
              );
            },
            icon: const Icon(Icons.done_all),
            label: const Text('Mark All Read'),
          ),
        ],
      ),
      body: BlocBuilder<ParentNotificationBloc, ParentNotificationState>(
        builder: (context, state) {
          final items = state is ParentNotificationLoaded
              ? state.items
              : <ParentNotificationEntity>[];

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: 210,
                        child: DropdownButtonFormField<ParentNotificationType?>(
                          initialValue: _type,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Types'),
                            ),
                            ...ParentNotificationType.values.map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item.name),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _type = value);
                            _load();
                          },
                        ),
                      ),
                      SizedBox(
                        width: 190,
                        child: DropdownButtonFormField<bool?>(
                          initialValue: _isRead,
                          decoration: const InputDecoration(
                            labelText: 'Read Status',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All')),
                            DropdownMenuItem(
                              value: false,
                              child: Text('Unread'),
                            ),
                            DropdownMenuItem(value: true, child: Text('Read')),
                          ],
                          onChanged: (value) {
                            setState(() => _isRead = value);
                            _load();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No notifications found.')),
                      ),
                    )
                  else
                    for (final item in items)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(_icon(item.type))),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${item.message}\n${_date(item.createdAt)}',
                          ),
                          isThreeLine: true,
                          onTap: () {
                            if (!item.isRead) {
                              context.read<ParentNotificationBloc>().add(
                                MarkParentNotificationRead(item.id),
                              );
                            }
                          },
                          trailing: IconButton(
                            tooltip: 'Delete',
                            onPressed: () {
                              context.read<ParentNotificationBloc>().add(
                                DeleteParentNotification(item.id),
                              );
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                ],
              ),
              if (state is ParentNotificationLoading)
                const LinearProgressIndicator(),
            ],
          );
        },
      ),
    );
  }

  static IconData _icon(ParentNotificationType type) => switch (type) {
    ParentNotificationType.attendance => Icons.fact_check_outlined,
    ParentNotificationType.homework => Icons.menu_book_outlined,
    ParentNotificationType.fee => Icons.payments_outlined,
    ParentNotificationType.exam => Icons.calendar_month_outlined,
    ParentNotificationType.result => Icons.grade_outlined,
    ParentNotificationType.notice => Icons.campaign_outlined,
    ParentNotificationType.calendar => Icons.event_outlined,
    ParentNotificationType.general => Icons.notifications_outlined,
  };

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
