import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_chat.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required this._getThreads,
    required GetChatMessages getMessages,
    required this._createThread,
    required this._sendMessage,
    required this._markRead,
  }) : _getMessages = getMessages,
       super(const ChatInitial()) {
    on<LoadChatThreads>(_loadThreads);
    on<OpenChatThread>(_openThread);
    on<CreateChatThreadRequested>(_create);
    on<SendChatMessageRequested>(_send);
  }

  final GetChatThreads _getThreads;
  final GetChatMessages _getMessages;
  final CreateChatThread _createThread;
  final SendChatMessage _sendMessage;
  final MarkChatThreadRead _markRead;

  Future<void> _loadThreads(
    LoadChatThreads event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());

    try {
      emit(ChatThreadsLoaded(threads: await _getThreads(event.userId)));
    } catch (error) {
      emit(ChatFailure(_message(error)));
    }
  }

  Future<void> _openThread(
    OpenChatThread event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());

    try {
      await _markRead(threadId: event.thread.id, userId: event.userId);

      emit(
        ChatThreadLoaded(
          thread: event.thread,
          messages: await _getMessages(event.thread.id),
          userId: event.userId,
        ),
      );
    } catch (error) {
      emit(ChatFailure(_message(error)));
    }
  }

  Future<void> _create(
    CreateChatThreadRequested event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _createThread(event.thread);
      emit(
        ChatThreadsLoaded(
          threads: await _getThreads(event.thread.createdBy),
          message: 'Conversation created.',
        ),
      );
    } catch (error) {
      emit(ChatFailure(_message(error)));
    }
  }

  Future<void> _send(
    SendChatMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatThreadLoaded) return;

    emit(
      ChatThreadLoaded(
        thread: current.thread,
        messages: current.messages,
        userId: current.userId,
        isProcessing: true,
      ),
    );

    try {
      await _sendMessage(event.message);

      emit(
        ChatThreadLoaded(
          thread: current.thread,
          messages: await _getMessages(current.thread.id),
          userId: current.userId,
          message: 'Message sent.',
        ),
      );
    } catch (error) {
      emit(
        ChatThreadLoaded(
          thread: current.thread,
          messages: current.messages,
          userId: current.userId,
          error: _message(error),
        ),
      );
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
