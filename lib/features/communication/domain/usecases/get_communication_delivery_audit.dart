import '../entities/communication_audit_entry_entity.dart';
import '../entities/communication_broadcast_entity.dart';
import '../entities/communication_delivery_summary_entity.dart';
import '../entities/push_delivery_log_entity.dart';
import '../entities/whatsapp_message_request_entity.dart';
import '../repositories/communication_audit_repository.dart';
import '../repositories/communication_broadcast_repository.dart';
import '../repositories/push_delivery_log_repository.dart';
import '../repositories/whatsapp_repository.dart';

class CommunicationDeliveryAuditData {
  const CommunicationDeliveryAuditData({
    required this.summary,
    required this.broadcasts,
    required this.pushLogs,
    required this.whatsappRequests,
    required this.auditEntries,
  });

  final CommunicationDeliverySummaryEntity summary;
  final List<CommunicationBroadcastEntity> broadcasts;
  final List<PushDeliveryLogEntity> pushLogs;
  final List<WhatsAppMessageRequestEntity> whatsappRequests;
  final List<CommunicationAuditEntryEntity> auditEntries;
}

class GetCommunicationDeliveryAudit {
  const GetCommunicationDeliveryAudit({
    required this._broadcastRepository,
    required this._pushLogRepository,
    required this._whatsappRepository,
    required this._auditRepository,
  });

  final CommunicationBroadcastRepository _broadcastRepository;
  final PushDeliveryLogRepository _pushLogRepository;
  final WhatsAppRepository _whatsappRepository;
  final CommunicationAuditRepository _auditRepository;

  Future<CommunicationDeliveryAuditData> call() async {
    final values = await Future.wait<Object>([
      _broadcastRepository.getBroadcasts(),
      _pushLogRepository.getLogs(),
      _whatsappRepository.getRequests(),
      _auditRepository.getEntries(),
    ]);

    final broadcasts = values[0] as List<CommunicationBroadcastEntity>;
    final pushLogs = values[1] as List<PushDeliveryLogEntity>;
    final whatsapp = values[2] as List<WhatsAppMessageRequestEntity>;
    final audit = values[3] as List<CommunicationAuditEntryEntity>;

    final sent =
        broadcasts.fold<int>(0, (sum, item) => sum + item.sentCount) +
        pushLogs
            .where(
              (item) =>
                  item.status == PushDeliveryStatus.sent ||
                  item.status == PushDeliveryStatus.delivered ||
                  item.status == PushDeliveryStatus.read,
            )
            .length +
        whatsapp
            .where(
              (item) =>
                  item.status == WhatsAppMessageStatus.sent ||
                  item.status == WhatsAppMessageStatus.delivered ||
                  item.status == WhatsAppMessageStatus.read,
            )
            .length;

    final delivered =
        broadcasts.fold<int>(0, (sum, item) => sum + item.deliveredCount) +
        pushLogs
            .where(
              (item) =>
                  item.status == PushDeliveryStatus.delivered ||
                  item.status == PushDeliveryStatus.read,
            )
            .length +
        whatsapp
            .where(
              (item) =>
                  item.status == WhatsAppMessageStatus.delivered ||
                  item.status == WhatsAppMessageStatus.read,
            )
            .length;

    final read =
        broadcasts.fold<int>(0, (sum, item) => sum + item.readCount) +
        pushLogs
            .where((item) => item.status == PushDeliveryStatus.read)
            .length +
        whatsapp
            .where((item) => item.status == WhatsAppMessageStatus.read)
            .length;

    final failed =
        broadcasts.fold<int>(0, (sum, item) => sum + item.failedCount) +
        pushLogs
            .where((item) => item.status == PushDeliveryStatus.failed)
            .length +
        whatsapp
            .where((item) => item.status == WhatsAppMessageStatus.failed)
            .length;

    final scheduled = broadcasts
        .where((item) => item.status == CommunicationBroadcastStatus.scheduled)
        .length;

    return CommunicationDeliveryAuditData(
      summary: CommunicationDeliverySummaryEntity(
        total: sent + failed + scheduled,
        sent: sent,
        delivered: delivered,
        read: read,
        failed: failed,
        scheduled: scheduled,
      ),
      broadcasts: broadcasts,
      pushLogs: pushLogs,
      whatsappRequests: whatsapp,
      auditEntries: audit,
    );
  }
}
