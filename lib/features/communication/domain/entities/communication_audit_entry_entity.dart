import 'package:equatable/equatable.dart';

enum CommunicationAuditAction {
  created,
  scheduled,
  queued,
  sent,
  delivered,
  read,
  failed,
  retried,
  archived,
  cancelled,
}

class CommunicationAuditEntryEntity extends Equatable {
  const CommunicationAuditEntryEntity({
    required this.id,
    required this.module,
    required this.referenceId,
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.createdAt,
    required this.details,
  });

  final String id;
  final String module;
  final String referenceId;
  final CommunicationAuditAction action;
  final String actorId;
  final String actorName;
  final DateTime createdAt;
  final Map<String, String> details;

  @override
  List<Object?> get props => [
    id,
    module,
    referenceId,
    action,
    actorId,
    actorName,
    createdAt,
    details,
  ];
}
