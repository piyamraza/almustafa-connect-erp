import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/whatsapp_template_entity.dart';

class WhatsAppTemplateModel extends WhatsAppTemplateEntity {
  const WhatsAppTemplateModel({
    required super.id,
    required super.name,
    required super.languageCode,
    required super.body,
    required super.variableNames,
    required super.status,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.headerText,
    super.footerText,
    super.rejectionReason,
  });

  factory WhatsAppTemplateModel.fromEntity(WhatsAppTemplateEntity entity) {
    return WhatsAppTemplateModel(
      id: entity.id,
      name: entity.name,
      languageCode: entity.languageCode,
      body: entity.body,
      variableNames: entity.variableNames,
      status: entity.status,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      headerText: entity.headerText,
      footerText: entity.footerText,
      rejectionReason: entity.rejectionReason,
    );
  }

  factory WhatsAppTemplateModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return WhatsAppTemplateModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      languageCode: map['languageCode'] as String? ?? 'en',
      body: map['body'] as String? ?? '',
      variableNames: List<String>.from(
        (map['variableNames'] as List?) ?? const [],
      ),
      status: WhatsAppTemplateStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => WhatsAppTemplateStatus.draft,
      ),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
      headerText: map['headerText'] as String? ?? '',
      footerText: map['footerText'] as String? ?? '',
      rejectionReason: map['rejectionReason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'languageCode': languageCode,
    'body': body,
    'variableNames': variableNames,
    'status': status.name,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'headerText': headerText,
    'footerText': footerText,
    'rejectionReason': rejectionReason,
    'schemaVersion': 1,
  };
}
