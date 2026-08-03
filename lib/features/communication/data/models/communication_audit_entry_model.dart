import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/communication_audit_entry_entity.dart';

class CommunicationAuditEntryModel extends CommunicationAuditEntryEntity {
  const CommunicationAuditEntryModel({
    required super.id,
    required super.module,
    required super.referenceId,
    required super.action,
    required super.actorId,
    required super.actorName,
    required super.createdAt,
    required super.details,
  });

  factory CommunicationAuditEntryModel.fromEntity(
    CommunicationAuditEntryEntity entity,
  ) {
    return CommunicationAuditEntryModel(
      id: entity.id,
      module: entity.module,
      referenceId: entity.referenceId,
      action: entity.action,
      actorId: entity.actorId,
      actorName: entity.actorName,
      createdAt: entity.createdAt,
      details: entity.details,
    );
  }

  factory CommunicationAuditEntryModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return CommunicationAuditEntryModel(
      id: map['id'] as String? ?? '',
      module: map['module'] as String? ?? '',
      referenceId: map['referenceId'] as String? ?? '',
      action: CommunicationAuditAction.values.firstWhere(
        (item) => item.name == map['action'],
        orElse: () => CommunicationAuditAction.created,
      ),
      actorId: map['actorId'] as String? ?? '',
      actorName: map['actorName'] as String? ?? '',
      createdAt: date(map['createdAt']),
      details: Map<String, String>.from((map['details'] as Map?) ?? const {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'module': module,
    'referenceId': referenceId,
    'action': action.name,
    'actorId': actorId,
    'actorName': actorName,
    'createdAt': createdAt.toIso8601String(),
    'details': details,
    'schemaVersion': 1,
  };
}
