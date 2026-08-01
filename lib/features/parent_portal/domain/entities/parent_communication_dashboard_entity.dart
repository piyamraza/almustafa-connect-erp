import 'package:equatable/equatable.dart';

class ParentFeeItemEntity extends Equatable {
  const ParentFeeItemEntity({
    required this.id,
    required this.title,
    required this.month,
    required this.amount,
    required this.paidAmount,
    required this.status,
    required this.dueDate,
    required this.challanUrl,
    required this.receiptUrl,
  });

  final String id;
  final String title;
  final String month;
  final double amount;
  final double paidAmount;
  final String status;
  final DateTime? dueDate;
  final String challanUrl;
  final String receiptUrl;

  double get outstanding => amount - paidAmount;

  @override
  List<Object?> get props => [
    id,
    title,
    month,
    amount,
    paidAmount,
    status,
    dueDate,
    challanUrl,
    receiptUrl,
  ];
}

class ParentNoticeItemEntity extends Equatable {
  const ParentNoticeItemEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.publishAt,
    required this.expireAt,
    required this.isRead,
    required this.acknowledgementRequired,
    required this.isAcknowledged,
    required this.attachmentUrls,
  });

  final String id;
  final String title;
  final String message;
  final String priority;
  final DateTime? publishAt;
  final DateTime? expireAt;
  final bool isRead;
  final bool acknowledgementRequired;
  final bool isAcknowledged;
  final List<String> attachmentUrls;

  @override
  List<Object?> get props => [
    id,
    title,
    message,
    priority,
    publishAt,
    expireAt,
    isRead,
    acknowledgementRequired,
    isAcknowledged,
    attachmentUrls,
  ];
}

class ParentCalendarItemEntity extends Equatable {
  const ParentCalendarItemEntity({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.description,
  });

  final String id;
  final String title;
  final String type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String description;

  @override
  List<Object?> get props => [id, title, type, startDate, endDate, description];
}

class ParentCommunicationDashboardEntity extends Equatable {
  const ParentCommunicationDashboardEntity({
    required this.totalOutstanding,
    required this.unpaidCount,
    required this.unreadNoticeCount,
    required this.pendingAcknowledgementCount,
    required this.upcomingEventCount,
    required this.fees,
    required this.notices,
    required this.calendarItems,
  });

  final double totalOutstanding;
  final int unpaidCount;
  final int unreadNoticeCount;
  final int pendingAcknowledgementCount;
  final int upcomingEventCount;
  final List<ParentFeeItemEntity> fees;
  final List<ParentNoticeItemEntity> notices;
  final List<ParentCalendarItemEntity> calendarItems;

  @override
  List<Object> get props => [
    totalOutstanding,
    unpaidCount,
    unreadNoticeCount,
    pendingAcknowledgementCount,
    upcomingEventCount,
    fees,
    notices,
    calendarItems,
  ];
}
