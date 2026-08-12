import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../communication/presentation/pages/in_app_chat_page.dart';
import '../../domain/entities/portal_notification_entity.dart';
import '../../domain/repositories/portal_notification_repository.dart';

class PortalNotificationCenterPage extends StatefulWidget {
  const PortalNotificationCenterPage({
    super.key,
    required this.recipientType,
    required this.recipientId,
    this.onOpen,
  });

  final PortalRecipientType recipientType;
  final String recipientId;
  final ValueChanged<PortalNotificationEntity>? onOpen;

  @override
  State<PortalNotificationCenterPage> createState() =>
      _PortalNotificationCenterPageState();
}

class _PortalNotificationCenterPageState
    extends State<PortalNotificationCenterPage> {
  final _repository = sl<PortalNotificationRepository>();
  List<PortalNotificationEntity> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await _repository.getNotifications(
        recipientType: widget.recipientType,
        recipientId: widget.recipientId,
      );
      if (!mounted) return;
      setState(() {
        _items = values;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _read(PortalNotificationEntity item) async {
    if (!item.isRead) await _repository.markRead(item.id);
    if (!mounted) return;
    final isChat = item.type == PortalNotificationType.chat ||
        (item.type == PortalNotificationType.general &&
            item.title == 'New internal chat message');
    if (isChat && item.referenceId.isNotEmpty) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => InAppChatPage(initialThreadId: item.referenceId),
        ),
      );
    } else if (widget.onOpen != null) {
      widget.onOpen!(item);
    }
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((item) => !item.isRead).length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications${unread == 0 ? '' : ' ($unread)'}'),
        actions: [
          TextButton.icon(
            onPressed: unread == 0
                ? null
                : () async {
                    await _repository.markAllRead(
                      recipientType: widget.recipientType,
                      recipientId: widget.recipientId,
                    );
                    await _load();
                  },
            icon: const Icon(Icons.done_all),
            label: const Text('Read all'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 160),
                  Text(_error!, textAlign: TextAlign.center),
                ],
              )
            : _items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 160),
                  Icon(Icons.notifications_none, size: 52),
                  SizedBox(height: 12),
                  Text('No notifications yet.', textAlign: TextAlign.center),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    color: item.isRead
                        ? null
                        : Theme.of(context).colorScheme.primaryContainer,
                    child: ListTile(
                      leading: CircleAvatar(child: Icon(_icon(item.type))),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.isRead
                              ? FontWeight.w500
                              : FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${item.message}\n${_date(item.createdAt)}',
                      ),
                      isThreeLine: true,
                      onTap: () => _read(item),
                    ),
                  );
                },
              ),
      ),
    );
  }

  static IconData _icon(PortalNotificationType type) => switch (type) {
    PortalNotificationType.homeworkQuestion => Icons.help_outline,
    PortalNotificationType.homeworkReply => Icons.question_answer_outlined,
    PortalNotificationType.attendance => Icons.fact_check_outlined,
    PortalNotificationType.homework => Icons.menu_book_outlined,
    PortalNotificationType.syllabus => Icons.school_outlined,
    PortalNotificationType.exam => Icons.event_note_outlined,
    PortalNotificationType.result => Icons.grade_outlined,
    PortalNotificationType.fee => Icons.payments_outlined,
    PortalNotificationType.notice => Icons.campaign_outlined,
    PortalNotificationType.leave => Icons.event_busy_outlined,
    PortalNotificationType.birthday => Icons.cake_outlined,
    PortalNotificationType.chat => Icons.forum_outlined,
    PortalNotificationType.general => Icons.notifications_outlined,
  };

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
