import 'package:equatable/equatable.dart';

import '../../domain/entities/communication_broadcast_entity.dart';

sealed class CommunicationBroadcastEvent extends Equatable {
  const CommunicationBroadcastEvent();

  @override
  List<Object?> get props => const [];
}

class LoadCommunicationBroadcasts extends CommunicationBroadcastEvent {
  const LoadCommunicationBroadcasts();
}

class QueueCommunicationBroadcastRequested extends CommunicationBroadcastEvent {
  const QueueCommunicationBroadcastRequested(this.broadcast);

  final CommunicationBroadcastEntity broadcast;

  @override
  List<Object?> get props => [broadcast];
}

class RetryCommunicationBroadcastRequested extends CommunicationBroadcastEvent {
  const RetryCommunicationBroadcastRequested(this.broadcast);

  final CommunicationBroadcastEntity broadcast;

  @override
  List<Object?> get props => [broadcast];
}
