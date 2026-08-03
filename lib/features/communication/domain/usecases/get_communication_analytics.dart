import '../entities/communication_analytics_entity.dart';
import '../entities/communication_message_entity.dart';
import '../entities/push_delivery_log_entity.dart';
import '../entities/whatsapp_message_request_entity.dart';
import 'get_communication_delivery_audit.dart';

class GetCommunicationAnalytics {
  const GetCommunicationAnalytics(this._getAudit);

  final GetCommunicationDeliveryAudit _getAudit;

  Future<CommunicationAnalyticsEntity> call() async {
    final data = await _getAudit();

    final broadcastTotal = data.broadcasts.length;
    final pushTotal = data.pushLogs.length;
    final whatsappTotal = data.whatsappRequests.length;

    final total = broadcastTotal + pushTotal + whatsappTotal;
    final sent = data.summary.sent;
    final delivered = data.summary.delivered;
    final read = data.summary.read;
    final failed = data.summary.failed;
    final scheduled = data.summary.scheduled;

    final channels = <CommunicationChannelAnalyticsEntity>[
      CommunicationChannelAnalyticsEntity(
        channel: 'In-App',
        total: data.broadcasts
            .where((item) => item.channels.contains(CommunicationChannel.inApp))
            .length,
        sent: data.broadcasts.fold<int>(
          0,
          (sum, item) => item.channels.contains(CommunicationChannel.inApp)
              ? sum + item.sentCount
              : sum,
        ),
        delivered: data.broadcasts.fold<int>(
          0,
          (sum, item) => item.channels.contains(CommunicationChannel.inApp)
              ? sum + item.deliveredCount
              : sum,
        ),
        read: data.broadcasts.fold<int>(
          0,
          (sum, item) => item.channels.contains(CommunicationChannel.inApp)
              ? sum + item.readCount
              : sum,
        ),
        failed: data.broadcasts.fold<int>(
          0,
          (sum, item) => item.channels.contains(CommunicationChannel.inApp)
              ? sum + item.failedCount
              : sum,
        ),
      ),
      CommunicationChannelAnalyticsEntity(
        channel: 'Push',
        total: pushTotal,
        sent: data.pushLogs
            .where(
              (item) =>
                  item.status == PushDeliveryStatus.sent ||
                  item.status == PushDeliveryStatus.delivered ||
                  item.status == PushDeliveryStatus.read,
            )
            .length,
        delivered: data.pushLogs
            .where(
              (item) =>
                  item.status == PushDeliveryStatus.delivered ||
                  item.status == PushDeliveryStatus.read,
            )
            .length,
        read: data.pushLogs
            .where((item) => item.status == PushDeliveryStatus.read)
            .length,
        failed: data.pushLogs
            .where((item) => item.status == PushDeliveryStatus.failed)
            .length,
      ),
      CommunicationChannelAnalyticsEntity(
        channel: 'WhatsApp',
        total: whatsappTotal,
        sent: data.whatsappRequests
            .where(
              (item) =>
                  item.status == WhatsAppMessageStatus.sent ||
                  item.status == WhatsAppMessageStatus.delivered ||
                  item.status == WhatsAppMessageStatus.read,
            )
            .length,
        delivered: data.whatsappRequests
            .where(
              (item) =>
                  item.status == WhatsAppMessageStatus.delivered ||
                  item.status == WhatsAppMessageStatus.read,
            )
            .length,
        read: data.whatsappRequests
            .where((item) => item.status == WhatsAppMessageStatus.read)
            .length,
        failed: data.whatsappRequests
            .where((item) => item.status == WhatsAppMessageStatus.failed)
            .length,
      ),
    ];

    final monthMap = <String, List<int>>{};

    void addMonth(
      DateTime date, {
      int totalValue = 0,
      int sentValue = 0,
      int deliveredValue = 0,
      int readValue = 0,
      int failedValue = 0,
    }) {
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final values = monthMap.putIfAbsent(key, () => [0, 0, 0, 0, 0]);

      values[0] += totalValue;
      values[1] += sentValue;
      values[2] += deliveredValue;
      values[3] += readValue;
      values[4] += failedValue;
    }

    for (final item in data.broadcasts) {
      addMonth(
        item.createdAt,
        totalValue: 1,
        sentValue: item.sentCount,
        deliveredValue: item.deliveredCount,
        readValue: item.readCount,
        failedValue: item.failedCount,
      );
    }

    for (final item in data.pushLogs) {
      addMonth(
        item.createdAt,
        totalValue: 1,
        sentValue:
            item.status == PushDeliveryStatus.sent ||
                item.status == PushDeliveryStatus.delivered ||
                item.status == PushDeliveryStatus.read
            ? 1
            : 0,
        deliveredValue:
            item.status == PushDeliveryStatus.delivered ||
                item.status == PushDeliveryStatus.read
            ? 1
            : 0,
        readValue: item.status == PushDeliveryStatus.read ? 1 : 0,
        failedValue: item.status == PushDeliveryStatus.failed ? 1 : 0,
      );
    }

    for (final item in data.whatsappRequests) {
      addMonth(
        item.createdAt,
        totalValue: 1,
        sentValue:
            item.status == WhatsAppMessageStatus.sent ||
                item.status == WhatsAppMessageStatus.delivered ||
                item.status == WhatsAppMessageStatus.read
            ? 1
            : 0,
        deliveredValue:
            item.status == WhatsAppMessageStatus.delivered ||
                item.status == WhatsAppMessageStatus.read
            ? 1
            : 0,
        readValue: item.status == WhatsAppMessageStatus.read ? 1 : 0,
        failedValue: item.status == WhatsAppMessageStatus.failed ? 1 : 0,
      );
    }

    final monthlyTrend = monthMap.entries.map((entry) {
      final parts = entry.key.split('-');
      final values = entry.value;

      return CommunicationMonthlyTrendEntity(
        month: DateTime(int.parse(parts[0]), int.parse(parts[1])),
        total: values[0],
        sent: values[1],
        delivered: values[2],
        read: values[3],
        failed: values[4],
      );
    }).toList()..sort((a, b) => a.month.compareTo(b.month));

    final audienceMap = <String, int>{};

    for (final item in data.broadcasts) {
      final key = item.audienceType.name;
      audienceMap[key] = (audienceMap[key] ?? 0) + 1;
    }

    final topAudiences =
        audienceMap.entries
            .map(
              (entry) => CommunicationAudienceAnalyticsEntity(
                audience: entry.key,
                total: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.total.compareTo(a.total));

    final recentActivity = <String>[
      ...data.auditEntries
          .take(10)
          .map((entry) => '${entry.module} â€¢ ${entry.action.name}'),
      ...data.broadcasts
          .take(10)
          .map((entry) => '${entry.title} â€¢ ${entry.status.name}'),
    ].take(12).toList();

    return CommunicationAnalyticsEntity(
      totalMessages: total,
      sent: sent,
      delivered: delivered,
      read: read,
      failed: failed,
      scheduled: scheduled,
      deliveryRate: sent == 0 ? 0 : delivered / sent,
      readRate: delivered == 0 ? 0 : read / delivered,
      failureRate: total == 0 ? 0 : failed / total,
      channels: channels,
      monthlyTrend: monthlyTrend.length <= 6
          ? monthlyTrend
          : monthlyTrend.sublist(monthlyTrend.length - 6),
      topAudiences: topAudiences.take(5).toList(),
      recentActivity: recentActivity,
    );
  }
}
