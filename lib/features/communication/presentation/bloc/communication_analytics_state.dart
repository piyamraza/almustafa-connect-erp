import 'package:equatable/equatable.dart';

import '../../domain/entities/communication_analytics_entity.dart';

sealed class CommunicationAnalyticsState extends Equatable {
  const CommunicationAnalyticsState();

  @override
  List<Object?> get props => const [];
}

class CommunicationAnalyticsInitial extends CommunicationAnalyticsState {
  const CommunicationAnalyticsInitial();
}

class CommunicationAnalyticsLoading extends CommunicationAnalyticsState {
  const CommunicationAnalyticsLoading();
}

class CommunicationAnalyticsLoaded extends CommunicationAnalyticsState {
  const CommunicationAnalyticsLoaded(this.analytics);

  final CommunicationAnalyticsEntity analytics;

  @override
  List<Object?> get props => [analytics];
}

class CommunicationAnalyticsFailure extends CommunicationAnalyticsState {
  const CommunicationAnalyticsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
