import 'package:equatable/equatable.dart';

enum WhatsAppBroadcastAudience {
  wholeSchool,
  parents,
  teachers,
  staff,
  students,
  classSection,
  selectedRecipients,
}

enum WhatsAppAutomationType {
  manual,
  feeReminder,
  attendanceAlert,
  homeworkNotification,
  resultPublished,
  examSchedule,
  holidayNotice,
}

enum WhatsAppBroadcastStatus {
  draft,
  queued,
  processing,
  completed,
  partiallyFailed,
  failed,
}

class WhatsAppBroadcastEntity extends Equatable {
  const WhatsAppBroadcastEntity({
    required this.id,
    required this.title,
    required this.templateName,
    required this.languageCode,
    required this.audience,
    required this.targetIds,
    required this.parameters,
    required this.automationType,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.attachmentUrl = '',
    this.scheduledAt,
    this.completedAt,
    this.totalRecipients = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.failureReason = '',
  });

  final String id;
  final String title;
  final String templateName;
  final String languageCode;
  final WhatsAppBroadcastAudience audience;
  final List<String> targetIds;
  final Map<String, String> parameters;
  final WhatsAppAutomationType automationType;
  final WhatsAppBroadcastStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String attachmentUrl;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final int totalRecipients;
  final int successCount;
  final int failureCount;
  final String failureReason;

  @override
  List<Object?> get props => [
    id,
    title,
    templateName,
    languageCode,
    audience,
    targetIds,
    parameters,
    automationType,
    status,
    createdBy,
    createdAt,
    updatedAt,
    attachmentUrl,
    scheduledAt,
    completedAt,
    totalRecipients,
    successCount,
    failureCount,
    failureReason,
  ];
}
