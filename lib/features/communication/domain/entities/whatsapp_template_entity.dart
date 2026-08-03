import 'package:equatable/equatable.dart';

enum WhatsAppTemplateStatus { draft, submitted, approved, rejected, disabled }

class WhatsAppTemplateEntity extends Equatable {
  const WhatsAppTemplateEntity({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.body,
    required this.variableNames,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.headerText = '',
    this.footerText = '',
    this.rejectionReason = '',
  });

  final String id;
  final String name;
  final String languageCode;
  final String body;
  final List<String> variableNames;
  final WhatsAppTemplateStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String headerText;
  final String footerText;
  final String rejectionReason;

  @override
  List<Object?> get props => [
    id,
    name,
    languageCode,
    body,
    variableNames,
    status,
    createdBy,
    createdAt,
    updatedAt,
    headerText,
    footerText,
    rejectionReason,
  ];
}
