import 'engagement_person_entity.dart';
import 'engagement_template_entity.dart';

class EngagementHistoryEntity {
  final String id;

  final EngagementType engagementType;

  final String personId;
  final EngagementPersonType personType;
  final String personName;

  final String templateId;
  final String templateName;

  final DateTime eventDate;

  final String generatedBy;
  final DateTime generatedAt;

  final bool imageGenerated;
  final bool pdfGenerated;
  final bool printed;
  final bool sharedWhatsapp;

  const EngagementHistoryEntity({
    required this.id,
    required this.engagementType,
    required this.personId,
    required this.personType,
    required this.personName,
    required this.templateId,
    required this.templateName,
    required this.eventDate,
    required this.generatedBy,
    required this.generatedAt,
    required this.imageGenerated,
    required this.pdfGenerated,
    required this.printed,
    required this.sharedWhatsapp,
  });

  bool get hasAnyAction =>
      imageGenerated || pdfGenerated || printed || sharedWhatsapp;

  EngagementHistoryEntity copyWith({
    String? id,
    EngagementType? engagementType,
    String? personId,
    EngagementPersonType? personType,
    String? personName,
    String? templateId,
    String? templateName,
    DateTime? eventDate,
    String? generatedBy,
    DateTime? generatedAt,
    bool? imageGenerated,
    bool? pdfGenerated,
    bool? printed,
    bool? sharedWhatsapp,
  }) {
    return EngagementHistoryEntity(
      id: id ?? this.id,
      engagementType: engagementType ?? this.engagementType,
      personId: personId ?? this.personId,
      personType: personType ?? this.personType,
      personName: personName ?? this.personName,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      eventDate: eventDate ?? this.eventDate,
      generatedBy: generatedBy ?? this.generatedBy,
      generatedAt: generatedAt ?? this.generatedAt,
      imageGenerated: imageGenerated ?? this.imageGenerated,
      pdfGenerated: pdfGenerated ?? this.pdfGenerated,
      printed: printed ?? this.printed,
      sharedWhatsapp: sharedWhatsapp ?? this.sharedWhatsapp,
    );
  }
}
