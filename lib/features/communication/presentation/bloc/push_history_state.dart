import 'package:equatable/equatable.dart';

import '../../domain/entities/push_delivery_log_entity.dart';
import '../../domain/entities/push_notification_request_entity.dart';

sealed class PushHistoryState extends Equatable {
  const PushHistoryState();

  @override
  List<Object?> get props => const [];
}

class PushHistoryInitial extends PushHistoryState {
  const PushHistoryInitial();
}

class PushHistoryLoading extends PushHistoryState {
  const PushHistoryLoading();
}

class PushHistoryLoaded extends PushHistoryState {
  const PushHistoryLoaded({
    required this.requests,
    required this.logs,
    this.isProcessing = false,
    this.message,
    this.error,
  });

  final List<PushNotificationRequestEntity> requests;
  final List<PushDeliveryLogEntity> logs;
  final bool isProcessing;
  final String? message;
  final String? error;

  int get sentCount =>
      requests.where((item) => item.status == PushRequestStatus.sent).length;

  int get failedCount =>
      requests.where((item) => item.status == PushRequestStatus.failed).length;

  int get deliveredCount => logs
      .where(
        (item) =>
            item.status == PushDeliveryStatus.delivered ||
            item.status == PushDeliveryStatus.read,
      )
      .length;

  PushHistoryLoaded copyWith({
    List<PushNotificationRequestEntity>? requests,
    List<PushDeliveryLogEntity>? logs,
    bool? isProcessing,
    String? message,
    String? error,
    bool clearMessages = false,
  }) {
    return PushHistoryLoaded(
      requests: requests ?? this.requests,
      logs: logs ?? this.logs,
      isProcessing: isProcessing ?? this.isProcessing,
      message: clearMessages ? null : message ?? this.message,
      error: clearMessages ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [requests, logs, isProcessing, message, error];
}

class PushHistoryFailure extends PushHistoryState {
  const PushHistoryFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
