import 'package:equatable/equatable.dart';

sealed class CommunicationAnalyticsEvent extends Equatable {
  const CommunicationAnalyticsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadCommunicationAnalytics extends CommunicationAnalyticsEvent {
  const LoadCommunicationAnalytics();
}
