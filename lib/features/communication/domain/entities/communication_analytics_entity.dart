import 'package:equatable/equatable.dart';

class CommunicationMonthlyTrendEntity extends Equatable {
  const CommunicationMonthlyTrendEntity({
    required this.month,
    required this.total,
    required this.sent,
    required this.delivered,
    required this.read,
    required this.failed,
  });

  final DateTime month;
  final int total;
  final int sent;
  final int delivered;
  final int read;
  final int failed;

  @override
  List<Object?> get props => [month, total, sent, delivered, read, failed];
}

class CommunicationChannelAnalyticsEntity extends Equatable {
  const CommunicationChannelAnalyticsEntity({
    required this.channel,
    required this.total,
    required this.sent,
    required this.delivered,
    required this.read,
    required this.failed,
  });

  final String channel;
  final int total;
  final int sent;
  final int delivered;
  final int read;
  final int failed;

  @override
  List<Object?> get props => [channel, total, sent, delivered, read, failed];
}

class CommunicationAudienceAnalyticsEntity extends Equatable {
  const CommunicationAudienceAnalyticsEntity({
    required this.audience,
    required this.total,
  });

  final String audience;
  final int total;

  @override
  List<Object?> get props => [audience, total];
}

class CommunicationAnalyticsEntity extends Equatable {
  const CommunicationAnalyticsEntity({
    required this.totalMessages,
    required this.sent,
    required this.delivered,
    required this.read,
    required this.failed,
    required this.scheduled,
    required this.deliveryRate,
    required this.readRate,
    required this.failureRate,
    required this.channels,
    required this.monthlyTrend,
    required this.topAudiences,
    required this.recentActivity,
  });

  final int totalMessages;
  final int sent;
  final int delivered;
  final int read;
  final int failed;
  final int scheduled;
  final double deliveryRate;
  final double readRate;
  final double failureRate;
  final List<CommunicationChannelAnalyticsEntity> channels;
  final List<CommunicationMonthlyTrendEntity> monthlyTrend;
  final List<CommunicationAudienceAnalyticsEntity> topAudiences;
  final List<String> recentActivity;

  @override
  List<Object?> get props => [
    totalMessages,
    sent,
    delivered,
    read,
    failed,
    scheduled,
    deliveryRate,
    readRate,
    failureRate,
    channels,
    monthlyTrend,
    topAudiences,
    recentActivity,
  ];
}
