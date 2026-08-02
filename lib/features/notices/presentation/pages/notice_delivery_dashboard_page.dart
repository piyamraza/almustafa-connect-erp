import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/notice_receipt_entity.dart';
import '../bloc/notice_receipt_bloc.dart';

class NoticeDeliveryDashboardPage extends StatelessWidget {
  const NoticeDeliveryDashboardPage({super.key, this.noticeId});

  final String? noticeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<NoticeReceiptBloc>()..add(LoadNoticeReceipts(noticeId: noticeId)),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  NoticeDeliveryStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Notice Delivery Report')),
      body: BlocBuilder<NoticeReceiptBloc, NoticeReceiptState>(
        builder: (context, state) {
          final loading = state is NoticeReceiptLoading;
          final items = state is NoticeReceiptLoaded
              ? state.items
              : <NoticeReceiptEntity>[];

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<NoticeDeliveryStatus?>(
                      initialValue: _filter,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...NoticeDeliveryStatus.values.map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.name.toUpperCase()),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _filter = value);
                        context.read<NoticeReceiptBloc>().add(
                          LoadNoticeReceipts(status: value),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Total: ${items.length}')),
                      Chip(
                        label: Text(
                          'Read: ${items.where((e) => e.status == NoticeDeliveryStatus.read || e.status == NoticeDeliveryStatus.acknowledged).length}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Acknowledged: ${items.where((e) => e.status == NoticeDeliveryStatus.acknowledged).length}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Pending: ${items.where((e) => e.status == NoticeDeliveryStatus.pending).length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final item in items)
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(item.recipientName),
                        subtitle: Text(
                          '${item.recipientType} • '
                          '${item.status.name.toUpperCase()}',
                        ),
                        trailing: item.acknowledgedAt == null
                            ? null
                            : const Icon(Icons.verified_outlined),
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
}
