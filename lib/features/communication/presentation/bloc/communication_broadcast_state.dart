import 'package:equatable/equatable.dart';

import '../../domain/entities/communication_broadcast_entity.dart';

sealed class CommunicationBroadcastState extends Equatable {
  const CommunicationBroadcastState();

  @override
  List<Object?> get props => const [];
}

class CommunicationBroadcastInitial extends CommunicationBroadcastState {
  const CommunicationBroadcastInitial();
}

class CommunicationBroadcastLoading extends CommunicationBroadcastState {
  const CommunicationBroadcastLoading();
}

class CommunicationBroadcastLoaded extends CommunicationBroadcastState {
  const CommunicationBroadcastLoaded({
    required this.broadcasts,
    this.isProcessing = false,
    this.message,
    this.error,
  });

  final List<CommunicationBroadcastEntity> broadcasts;
  final bool isProcessing;
  final String? message;
  final String? error;

  int get sentCount => broadcasts
      .where((item) => item.status == CommunicationBroadcastStatus.sent)
      .length;

  int get failedCount => broadcasts
      .where(
        (item) =>
            item.status == CommunicationBroadcastStatus.failed ||
            item.status == CommunicationBroadcastStatus.partiallyFailed,
      )
      .length;

  CommunicationBroadcastLoaded copyWith({
    List<CommunicationBroadcastEntity>? broadcasts,
    bool? isProcessing,
    String? message,
    String? error,
    bool clearMessages = false,
  }) {
    return CommunicationBroadcastLoaded(
      broadcasts: broadcasts ?? this.broadcasts,
      isProcessing: isProcessing ?? this.isProcessing,
      message: clearMessages ? null : message ?? this.message,
      error: clearMessages ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [broadcasts, isProcessing, message, error];
}

class CommunicationBroadcastFailure extends CommunicationBroadcastState {
  const CommunicationBroadcastFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
