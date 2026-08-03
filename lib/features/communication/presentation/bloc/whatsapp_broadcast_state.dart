import 'package:equatable/equatable.dart';

import '../../domain/entities/whatsapp_broadcast_entity.dart';

sealed class WhatsAppBroadcastState extends Equatable {
  const WhatsAppBroadcastState();

  @override
  List<Object?> get props => const [];
}

class WhatsAppBroadcastInitial extends WhatsAppBroadcastState {
  const WhatsAppBroadcastInitial();
}

class WhatsAppBroadcastLoading extends WhatsAppBroadcastState {
  const WhatsAppBroadcastLoading();
}

class WhatsAppBroadcastLoaded extends WhatsAppBroadcastState {
  const WhatsAppBroadcastLoaded({
    required this.broadcasts,
    this.isProcessing = false,
    this.message,
    this.error,
  });

  final List<WhatsAppBroadcastEntity> broadcasts;
  final bool isProcessing;
  final String? message;
  final String? error;

  WhatsAppBroadcastLoaded copyWith({
    List<WhatsAppBroadcastEntity>? broadcasts,
    bool? isProcessing,
    String? message,
    String? error,
    bool clearMessages = false,
  }) {
    return WhatsAppBroadcastLoaded(
      broadcasts: broadcasts ?? this.broadcasts,
      isProcessing: isProcessing ?? this.isProcessing,
      message: clearMessages ? null : message ?? this.message,
      error: clearMessages ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [broadcasts, isProcessing, message, error];
}

class WhatsAppBroadcastFailure extends WhatsAppBroadcastState {
  const WhatsAppBroadcastFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
