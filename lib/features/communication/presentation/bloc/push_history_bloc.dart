import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_push_history.dart';
import '../../domain/usecases/retry_failed_push.dart';
import 'push_history_event.dart';
import 'push_history_state.dart';

class PushHistoryBloc extends Bloc<PushHistoryEvent, PushHistoryState> {
  PushHistoryBloc({
    required this._getHistory,
    required this._retryPush,
  }) : super(const PushHistoryInitial()) {
    on<LoadPushHistory>(_load);
    on<RetryPushRequested>(_retry);
  }

  final GetPushHistory _getHistory;
  final RetryFailedPush _retryPush;

  Future<void> _load(
    LoadPushHistory event,
    Emitter<PushHistoryState> emit,
  ) async {
    emit(const PushHistoryLoading());
    await _reload(emit);
  }

  Future<void> _retry(
    RetryPushRequested event,
    Emitter<PushHistoryState> emit,
  ) async {
    final current = state;
    if (current is PushHistoryLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }

    try {
      await _retryPush(event.request);
      await _reload(emit, message: 'Push notification retry requested.');
    } catch (error) {
      if (current is PushHistoryLoaded) {
        emit(
          current.copyWith(
            isProcessing: false,
            error: _message(error),
            clearMessages: true,
          ),
        );
      } else {
        emit(PushHistoryFailure(_message(error)));
      }
    }
  }

  Future<void> _reload(
    Emitter<PushHistoryState> emit, {
    String? message,
  }) async {
    try {
      final history = await _getHistory();
      emit(
        PushHistoryLoaded(
          requests: history.requests,
          logs: history.logs,
          message: message,
        ),
      );
    } catch (error) {
      emit(PushHistoryFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
