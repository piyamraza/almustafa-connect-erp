import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/push_notification_request_entity.dart';
import '../bloc/push_history_bloc.dart';
import '../bloc/push_history_event.dart';
import '../bloc/push_history_state.dart';

class PushNotificationHistoryPage extends StatelessWidget {
  const PushNotificationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PushHistoryBloc>()..add(const LoadPushHistory()),
      child: const _PushNotificationHistoryView(),
    );
  }
}

class _PushNotificationHistoryView extends StatelessWidget {
  const _PushNotificationHistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notification History'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<PushHistoryBloc, PushHistoryState>(
        listener: (context, state) {
          if (state is! PushHistoryLoaded) return;
          final text = state.error ?? state.message;
          if (text == null) return;

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
        },
        builder: (context, state) {
          if (state is PushHistoryInitial || state is PushHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PushHistoryFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as PushHistoryLoaded;

          return Column(
            children: [
              if (data.isProcessing) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryChip(
                      label: 'Requests',
                      value: data.requests.length,
                    ),
                    _SummaryChip(label: 'Sent', value: data.sentCount),
                    _SummaryChip(
                      label: 'Delivered',
                      value: data.deliveredCount,
                    ),
                    _SummaryChip(label: 'Failed', value: data.failedCount),
                  ],
                ),
              ),
              Expanded(
                child: data.requests.isEmpty
                    ? const Center(
                        child: Text('No push notification history found.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: data.requests.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final request = data.requests[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(
                                  request.status == PushRequestStatus.failed
                                      ? Icons.error_outline
                                      : Icons.notifications_active_outlined,
                                ),
                              ),
                              title: Text(request.title),
                              subtitle: Text(
                                '${request.targetType.name} â€¢ '
                                '${request.targetValue} â€¢ '
                                '${request.status.name}',
                              ),
                              trailing:
                                  request.status == PushRequestStatus.failed
                                  ? IconButton(
                                      tooltip: 'Retry',
                                      onPressed: data.isProcessing
                                          ? null
                                          : () {
                                              context
                                                  .read<PushHistoryBloc>()
                                                  .add(
                                                    RetryPushRequested(request),
                                                  );
                                            },
                                      icon: const Icon(Icons.refresh),
                                    )
                                  : Text(_date(request.createdAt)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year}';
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}
