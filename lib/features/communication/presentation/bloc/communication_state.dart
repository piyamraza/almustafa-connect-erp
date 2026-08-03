import 'package:equatable/equatable.dart';

import '../../domain/entities/communication_message_entity.dart';

sealed class CommunicationState extends Equatable {
  const CommunicationState();

  @override
  List<Object?> get props => const [];
}

class CommunicationInitial extends CommunicationState {
  const CommunicationInitial();
}

class CommunicationLoading extends CommunicationState {
  const CommunicationLoading();
}

class CommunicationLoaded extends CommunicationState {
  const CommunicationLoaded({
    required this.messages,
    this.isProcessing = false,
    this.message,
    this.error,
  });

  final List<CommunicationMessageEntity> messages;
  final bool isProcessing;
  final String? message;
  final String? error;

  int get publishedCount => messages
      .where((item) => item.status == CommunicationMessageStatus.published)
      .length;

  int get scheduledCount => messages
      .where((item) => item.status == CommunicationMessageStatus.scheduled)
      .length;

  CommunicationLoaded copyWith({
    List<CommunicationMessageEntity>? messages,
    bool? isProcessing,
    String? message,
    String? error,
    bool clearMessages = false,
  }) {
    return CommunicationLoaded(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      message: clearMessages ? null : message ?? this.message,
      error: clearMessages ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [messages, isProcessing, message, error];
}

class CommunicationFailure extends CommunicationState {
  const CommunicationFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
