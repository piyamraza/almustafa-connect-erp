import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/notice_entity.dart';
import '../../domain/services/notice_delivery_service.dart';
import '../bloc/notice_bloc.dart';
import 'notice_delivery_dashboard_page.dart';
import 'notice_form_page.dart';

const _pageBackground = Color(0xFFF3F6FB);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

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

  void _resetFilters() {
    setState(() {
      _status = null;
      _audience = null;
      _priority = null;
      _session.text = '2026-2027';
    });
    _load();
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

  Future<void> _processSchedule() async {
    final changed = await sl<NoticeDeliveryService>().processScheduledNotices(
      academicSession: _session.text.trim(),
    );

    if (!mounted) return;

    _load();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$changed scheduled/expired notice(s) processed.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: const Text('Notices & Circulars'),
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Process Schedule',
            onPressed: _processSchedule,
            icon: const Icon(Icons.schedule_send_outlined),
          ),
          IconButton(
            tooltip: 'Delivery Dashboard',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const NoticeDeliveryDashboardPage(),
                ),
              );
            },
            icon: const Icon(Icons.mark_email_read_outlined),
          ),
          const SizedBox(width: 8),
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
                children: [
                  _buildHeroHeader(),
                  const SizedBox(height: 14),
                  _buildFilters(),
                  const SizedBox(height: 14),
                  _NoticeStats(items: items),
                  const SizedBox(height: 14),
                  if (items.isEmpty)
                    const _EmptyNotices()
                  else
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NoticeCard(
                          item: item,
                          onOpen: () => _open(item),
                          onShare: () =>
                              sl<NoticeDeliveryService>().shareNotice(item),
                          onPublish: () {
                            context.read<NoticeBloc>().add(
                              ChangeNoticeStatus(item, NoticeStatus.published),
                            );
                          },
                          onArchive: () {
                            context.read<NoticeBloc>().add(
                              ChangeNoticeStatus(item, NoticeStatus.archived),
                            );
                          },
                          onDelete: () {
                            context.read<NoticeBloc>().add(
                              DeleteNotice(item.id),
                            );
                          },
                        ),
                      ),
                ],
              ),
              if (loading) const LinearProgressIndicator(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: .18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          _HeaderIcon(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'School Notices & Circulars',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Create, schedule, publish and monitor school communication.',
                  style: TextStyle(color: Color(0xFFF3E8FF), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth >= 1050
                ? 210.0
                : constraints.maxWidth >= 700
                ? 230.0
                : constraints.maxWidth;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: TextField(
                    controller: _session,
                    decoration: const InputDecoration(
                      labelText: 'Academic Session',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                _enumFilter<NoticeStatus>(
                  width: fieldWidth,
                  label: 'Status',
                  value: _status,
                  values: NoticeStatus.values,
                  icon: Icons.flag_outlined,
                  onChanged: (value) => setState(() => _status = value),
                ),
                _enumFilter<NoticeAudienceType>(
                  width: fieldWidth,
                  label: 'Audience',
                  value: _audience,
                  values: NoticeAudienceType.values,
                  icon: Icons.groups_outlined,
                  onChanged: (value) => setState(() => _audience = value),
                ),
                _enumFilter<NoticePriority>(
                  width: fieldWidth,
                  label: 'Priority',
                  value: _priority,
                  values: NoticePriority.values,
                  icon: Icons.priority_high,
                  onChanged: (value) => setState(() => _priority = value),
                ),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Load'),
                ),
                OutlinedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _enumFilter<T extends Enum>({
    required double width,
    required String label,
    required T? value,
    required List<T> values,
    required IconData icon,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem<T?>(value: null, child: const Text('All')),
          ...values.map(
            (item) => DropdownMenuItem<T?>(
              value: item,
              child: Text(
                _enumLabel(item.name),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  String _enumLabel(String value) {
    final spaced = value.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    );
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .25)),
      ),
      child: const Icon(Icons.campaign_outlined, color: Colors.white, size: 27),
    );
  }
}

class _NoticeStats extends StatelessWidget {
  const _NoticeStats({required this.items});

  final List<NoticeEntity> items;

  @override
  Widget build(BuildContext context) {
    final draft = items.where((e) => e.status == NoticeStatus.draft).length;
    final scheduled = items
        .where((e) => e.status == NoticeStatus.scheduled)
        .length;
    final published = items
        .where((e) => e.status == NoticeStatus.published)
        .length;
    final urgent = items
        .where(
          (e) =>
              e.priority == NoticePriority.urgent ||
              e.priority == NoticePriority.emergency,
        )
        .length;

    final stats = [
      _StatData(
        label: 'Total',
        value: items.length,
        icon: Icons.inbox_outlined,
        color: const Color(0xFF2563EB),
      ),
      _StatData(
        label: 'Draft',
        value: draft,
        icon: Icons.edit_note_outlined,
        color: const Color(0xFF64748B),
      ),
      _StatData(
        label: 'Scheduled',
        value: scheduled,
        icon: Icons.schedule_outlined,
        color: const Color(0xFF7C3AED),
      ),
      _StatData(
        label: 'Published',
        value: published,
        icon: Icons.public_outlined,
        color: const Color(0xFF059669),
      ),
      _StatData(
        label: 'Urgent',
        value: urgent,
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFDC2626),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1000
            ? (constraints.maxWidth - 48) / 5
            : constraints.maxWidth >= 600
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: _StatCard(data: stat),
              ),
          ],
        );
      },
    );
  }
}

class _StatData {
  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [data.color.withValues(alpha: .13), Colors.white],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: data.color.withValues(alpha: .20)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: data.color.withValues(alpha: .13),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${data.value}',
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(data.label, style: const TextStyle(color: _textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.item,
    required this.onOpen,
    required this.onShare,
    required this.onPublish,
    required this.onArchive,
    required this.onDelete,
  });

  final NoticeEntity item;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onPublish;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  Color get _priorityColor => switch (item.priority) {
    NoticePriority.emergency => const Color(0xFFDC2626),
    NoticePriority.urgent => const Color(0xFFEA580C),
    NoticePriority.important => const Color(0xFFD97706),
    _ => const Color(0xFF2563EB),
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: _priorityColor, width: 5)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: CircleAvatar(
              backgroundColor: _priorityColor.withValues(alpha: .12),
              child: Icon(
                item.priority == NoticePriority.emergency
                    ? Icons.warning_amber_rounded
                    : Icons.campaign_outlined,
                color: _priorityColor,
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${item.audienceType.name} • '
                '${item.priority.name.toUpperCase()} • '
                '${item.status.name.toUpperCase()}\n'
                '${item.message}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'share':
                    onShare();
                  case 'publish':
                    onPublish();
                  case 'archive':
                    onArchive();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'share', child: Text('Share / WhatsApp')),
                PopupMenuItem(value: 'publish', child: Text('Publish')),
                PopupMenuItem(value: 'archive', child: Text('Archive')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotices extends StatelessWidget {
  const _EmptyNotices();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: Column(
          children: [
            const Icon(
              Icons.notifications_none_outlined,
              size: 58,
              color: Color(0xFF7C3AED),
            ),
            const SizedBox(height: 12),
            const Text(
              'No notices found',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create a new notice or change the filters.',
              style: TextStyle(color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
