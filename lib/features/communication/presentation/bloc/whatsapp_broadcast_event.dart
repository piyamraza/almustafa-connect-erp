import 'package:equatable/equatable.dart';

import '../../domain/entities/whatsapp_broadcast_entity.dart';

sealed class WhatsAppBroadcastEvent extends Equatable {
  const WhatsAppBroadcastEvent();

  @override
  List<Object?> get props => const [];
}

class LoadWhatsAppBroadcasts extends WhatsAppBroadcastEvent {
  const LoadWhatsAppBroadcasts();
}

class QueueWhatsAppBroadcastRequested extends WhatsAppBroadcastEvent {
  const QueueWhatsAppBroadcastRequested(this.broadcast);

  final WhatsAppBroadcastEntity broadcast;

  @override
  List<Object?> get props => [broadcast];
}

class RetryWhatsAppBroadcastRequested extends WhatsAppBroadcastEvent {
  const RetryWhatsAppBroadcastRequested(this.broadcast);

  final WhatsAppBroadcastEntity broadcast;

  @override
  List<Object?> get props => [broadcast];
}
