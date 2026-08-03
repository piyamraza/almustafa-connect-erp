import 'package:equatable/equatable.dart';

import '../../domain/entities/communication_audit_entry_entity.dart';
import '../../domain/entities/communication_broadcast_entity.dart';
import '../../domain/entities/communication_delivery_summary_entity.dart';
import '../../domain/entities/push_delivery_log_entity.dart';
import '../../domain/entities/whatsapp_message_request_entity.dart';

sealed class CommunicationAuditState extends Equatable {
  const CommunicationAuditState();

  @override
  List<Object?> get props => const [];
}

class CommunicationAuditInitial extends CommunicationAuditState {
  const CommunicationAuditInitial();
}

class CommunicationAuditLoading extends CommunicationAuditState {
  const CommunicationAuditLoading();
}

class CommunicationAuditLoaded extends CommunicationAuditState {
  const CommunicationAuditLoaded({
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

  @override
  List<Object?> get props => [
    summary,
    broadcasts,
    pushLogs,
    whatsappRequests,
    auditEntries,
  ];
}

class CommunicationAuditFailure extends CommunicationAuditState {
  const CommunicationAuditFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
