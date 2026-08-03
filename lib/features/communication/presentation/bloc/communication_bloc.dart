import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/delete_communication_message.dart';
import '../../domain/usecases/get_communication_messages.dart';
import '../../domain/usecases/save_communication_message.dart';
import 'communication_event.dart';
import 'communication_state.dart';

class CommunicationBloc extends Bloc<CommunicationEvent, CommunicationState> {
  CommunicationBloc({
    required this._getMessages,
    required SaveCommunicationMessage saveMessage,
    required this._deleteMessage,
  }) : _saveMessage = saveMessage,
       super(const CommunicationInitial()) {
    on<LoadCommunicationDashboard>(_load);
    on<SaveCommunicationMessageRequested>(_save);
    on<DeleteCommunicationMessageRequested>(_delete);
  }

  final GetCommunicationMessages _getMessages;
  final SaveCommunicationMessage _saveMessage;
  final DeleteCommunicationMessage _deleteMessage;

  Future<void> _load(
    LoadCommunicationDashboard event,
    Emitter<CommunicationState> emit,
  ) async {
    emit(const CommunicationLoading());
    await _reload(emit);
  }

  Future<void> _save(
    SaveCommunicationMessageRequested event,
    Emitter<CommunicationState> emit,
  ) async {
    final current = state;
    if (current is CommunicationLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }

    try {
      await _saveMessage(event.message);
      await _reload(emit, message: 'Announcement saved successfully.');
    } catch (error) {
      if (current is CommunicationLoaded) {
        emit(
          current.copyWith(
            isProcessing: false,
            error: _message(error),
            clearMessages: true,
          ),
        );
      } else {
        emit(CommunicationFailure(_message(error)));
      }
    }
  }

  Future<void> _delete(
    DeleteCommunicationMessageRequested event,
    Emitter<CommunicationState> emit,
  ) async {
    final current = state;
    if (current is CommunicationLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }

    try {
      await _deleteMessage(event.messageId);
      await _reload(emit, message: 'Announcement deleted successfully.');
    } catch (error) {
      if (current is CommunicationLoaded) {
        emit(
          current.copyWith(
            isProcessing: false,
            error: _message(error),
            clearMessages: true,
          ),
        );
      } else {
        emit(CommunicationFailure(_message(error)));
      }
    }
  }

  Future<void> _reload(
    Emitter<CommunicationState> emit, {
    String? message,
  }) async {
    try {
      emit(
        CommunicationLoaded(messages: await _getMessages(), message: message),
      );
    } catch (error) {
      emit(CommunicationFailure(_message(error)));
    }
  }

  String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
