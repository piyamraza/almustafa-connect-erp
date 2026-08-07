import '../../domain/entities/engagement_history_entity.dart';
import '../../domain/entities/engagement_person_entity.dart';
import '../../domain/entities/engagement_template_entity.dart';

class EngagementHistoryModel extends EngagementHistoryEntity {
  const EngagementHistoryModel({
    required super.id,
    required super.engagementType,
    required super.personId,
    required super.personType,
    required super.personName,
    required super.templateId,
    required super.templateName,
    required super.eventDate,
    required super.generatedBy,
    required super.generatedAt,
    required super.imageGenerated,
    required super.pdfGenerated,
    required super.printed,
    required super.sharedWhatsapp,
  });

  factory EngagementHistoryModel.fromMap(Map<String, dynamic> map) {
    return EngagementHistoryModel(
      id: map['id'] as String? ?? '',
      engagementType: _engagementTypeFromString(
        map['engagementType'] as String? ?? '',
      ),
      personId: map['personId'] as String? ?? '',
      personType: _personTypeFromString(map['personType'] as String? ?? ''),
      personName: map['personName'] as String? ?? '',
      templateId: map['templateId'] as String? ?? '',
      templateName: map['templateName'] as String? ?? '',
      eventDate: _dateTimeFromValue(map['eventDate']),
      generatedBy: map['generatedBy'] as String? ?? '',
      generatedAt: _dateTimeFromValue(map['generatedAt']),
      imageGenerated: map['imageGenerated'] as bool? ?? false,
      pdfGenerated: map['pdfGenerated'] as bool? ?? false,
      printed: map['printed'] as bool? ?? false,
      sharedWhatsapp: map['sharedWhatsapp'] as bool? ?? false,
    );
  }

  factory EngagementHistoryModel.fromEntity(EngagementHistoryEntity entity) {
    return EngagementHistoryModel(
      id: entity.id,
      engagementType: entity.engagementType,
      personId: entity.personId,
      personType: entity.personType,
      personName: entity.personName,
      templateId: entity.templateId,
      templateName: entity.templateName,
      eventDate: entity.eventDate,
      generatedBy: entity.generatedBy,
      generatedAt: entity.generatedAt,
      imageGenerated: entity.imageGenerated,
      pdfGenerated: entity.pdfGenerated,
      printed: entity.printed,
      sharedWhatsapp: entity.sharedWhatsapp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'engagementType': engagementType.name,
      'personId': personId,
      'personType': personType.name,
      'personName': personName,
      'templateId': templateId,
      'templateName': templateName,
      'eventDate': eventDate.toIso8601String(),
      'generatedBy': generatedBy,
      'generatedAt': generatedAt.toIso8601String(),
      'imageGenerated': imageGenerated,
      'pdfGenerated': pdfGenerated,
      'printed': printed,
      'sharedWhatsapp': sharedWhatsapp,
    };
  }

  static EngagementType _engagementTypeFromString(String value) {
    return EngagementType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => EngagementType.other,
    );
  }

  static EngagementPersonType _personTypeFromString(String value) {
    return EngagementPersonType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => EngagementPersonType.other,
    );
  }

  static DateTime _dateTimeFromValue(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
