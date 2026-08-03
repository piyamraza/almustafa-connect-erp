import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => const [];
}

class LoadChatThreads extends ChatEvent {
  const LoadChatThreads(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class OpenChatThread extends ChatEvent {
  const OpenChatThread({required this.thread, required this.userId});

  final ChatThreadEntity thread;
  final String userId;

  @override
  List<Object?> get props => [thread, userId];
}

class CreateChatThreadRequested extends ChatEvent {
  const CreateChatThreadRequested(this.thread);

  final ChatThreadEntity thread;

  @override
  List<Object?> get props => [thread];
}

class SendChatMessageRequested extends ChatEvent {
  const SendChatMessageRequested(this.message);

  final ChatMessageEntity message;

  @override
  List<Object?> get props => [message];
}
