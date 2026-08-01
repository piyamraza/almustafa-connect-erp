import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/notice_entity.dart';
import '../bloc/notice_bloc.dart';
import 'notice_form_page.dart';

import '../../domain/services/notice_delivery_service.dart';
import 'notice_delivery_dashboard_page.dart';

class NoticesDashboardPage extends StatelessWidget {
  const NoticesDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NoticeBloc>()..add(const LoadNotices('2026-2027')),
      child: const _NoticesDashboardView(),
    );
  }
}

class _NoticesDashboardView extends StatefulWidget {
  const _NoticesDashboardView();

  @override
  State<_NoticesDashboardView> createState() => _NoticesDashboardViewState();
}

class _NoticesDashboardViewState extends State<_NoticesDashboardView> {
  final _session = TextEditingController(text: '2026-2027');
  NoticeStatus? _status;
  NoticeAudienceType? _audience;
  NoticePriority? _priority;

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  void _load() {
    context.read<NoticeBloc>().add(
      LoadNotices(
        _session.text.trim(),
        status: _status,
        audienceType: _audience,
        priority: _priority,
      ),
    );
  }

  Future<void> _open([NoticeEntity? existing]) async {
    final result = await Navigator.of(context).push<NoticeEntity>(
      MaterialPageRoute(
        builder: (_) => NoticeFormPage(
          academicSession: _session.text.trim(),
          existing: existing,
        ),
      ),
    );

    if (result != null && mounted) {
      context.read<NoticeBloc>().add(SaveNotice(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notices & Circulars'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final changed = await sl<NoticeDeliveryService>()
                  .processScheduledNotices(
                    academicSession: _session.text.trim(),
                  );
              if (context.mounted) {
                _load();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$changed scheduled/expired notice(s) processed.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.schedule_send_outlined),
            label: const Text('Process Schedule'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const NoticeDeliveryDashboardPage(),
                ),
              );
            },
            icon: const Icon(Icons.mark_email_read_outlined),
            label: const Text('Delivery'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _open,
        icon: const Icon(Icons.add),
        label: const Text('Create Notice'),
      ),
      body: BlocConsumer<NoticeBloc, NoticeState>(
        listener: (context, state) {
          final message = switch (state) {
            NoticeLoaded(:final message) => message,
            NoticeError(:final message) => message,
            _ => null,
          };

          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          final loading = state is NoticeLoading;
          final items = state is NoticeLoaded ? state.items : <NoticeEntity>[];

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: _session,
                              decoration: const InputDecoration(
                                labelText: 'Academic Session',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          _enumFilter<NoticeStatus>(
                            label: 'Status',
                            value: _status,
                            values: NoticeStatus.values,
                            onChanged: (value) =>
                                setState(() => _status = value),
                          ),
                          _enumFilter<NoticeAudienceType>(
                            label: 'Audience',
                            value: _audience,
                            values: NoticeAudienceType.values,
                            onChanged: (value) =>
                                setState(() => _audience = value),
                          ),
                          _enumFilter<NoticePriority>(
                            label: 'Priority',
                            value: _priority,
                            values: NoticePriority.values,
                            onChanged: (value) =>
                                setState(() => _priority = value),
                          ),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Load'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Total: ${items.length}')),
                      Chip(
                        label: Text(
                          'Draft: ${items.where((e) => e.status == NoticeStatus.draft).length}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Scheduled: ${items.where((e) => e.status == NoticeStatus.scheduled).length}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Published: ${items.where((e) => e.status == NoticeStatus.published).length}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Urgent: ${items.where((e) => e.priority == NoticePriority.urgent || e.priority == NoticePriority.emergency).length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No notices found.')),
                      ),
                    )
                  else
                    for (final item in items)
                      Card(
                        child: ListTile(
                          onTap: () => _open(item),
                          leading: CircleAvatar(
                            child: Icon(
                              item.priority == NoticePriority.emergency
                                  ? Icons.warning_amber
                                  : Icons.campaign_outlined,
                            ),
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.audienceType.name} • '
                            '${item.priority.name.toUpperCase()} • '
                            '${item.status.name.toUpperCase()}\n'
                            '${item.message}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              switch (action) {
                                case 'share':
                                  sl<NoticeDeliveryService>().shareNotice(item);
                                case 'publish':
                                  context.read<NoticeBloc>().add(
                                    ChangeNoticeStatus(
                                      item,
                                      NoticeStatus.published,
                                    ),
                                  );
                                case 'archive':
                                  context.read<NoticeBloc>().add(
                                    ChangeNoticeStatus(
                                      item,
                                      NoticeStatus.archived,
                                    ),
                                  );
                                case 'delete':
                                  context.read<NoticeBloc>().add(
                                    DeleteNotice(item.id),
                                  );
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'share',
                                child: Text('Share / WhatsApp'),
                              ),
                              PopupMenuItem(
                                value: 'publish',
                                child: Text('Publish'),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: Text('Archive'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 80),
                ],
              ),
              if (loading) const LinearProgressIndicator(),
            ],
          );
        },
      ),
    );
  }

  Widget _enumFilter<T extends Enum>({
    required String label,
    required T? value,
    required List<T> values,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem<T?>(value: null, child: Text('All')),
          ...values.map(
            (item) => DropdownMenuItem<T?>(value: item, child: Text(item.name)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
