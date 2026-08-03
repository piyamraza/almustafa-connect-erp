import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => const [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatThreadsLoaded extends ChatState {
  const ChatThreadsLoaded({
    required this.threads,
    this.isProcessing = false,
    this.message,
    this.error,
  });

  final List<ChatThreadEntity> threads;
  final bool isProcessing;
  final String? message;
  final String? error;

  @override
  List<Object?> get props => [threads, isProcessing, message, error];
}

class ChatThreadLoaded extends ChatState {
  const ChatThreadLoaded({
    required this.thread,
    required this.messages,
    required this.userId,
    this.isProcessing = false,
    this.message,
    this.error,
  });

  final ChatThreadEntity thread;
  final List<ChatMessageEntity> messages;
  final String userId;
  final bool isProcessing;
  final String? message;
  final String? error;

  @override
  List<Object?> get props => [
    thread,
    messages,
    userId,
    isProcessing,
    message,
    error,
  ];
}

class ChatFailure extends ChatState {
  const ChatFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
