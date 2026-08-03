import 'package:equatable/equatable.dart';

sealed class CommunicationAuditEvent extends Equatable {
  const CommunicationAuditEvent();

  @override
  List<Object?> get props => const [];
}

class LoadCommunicationAudit extends CommunicationAuditEvent {
  const LoadCommunicationAudit();
}
