import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_cashbook.dart';
import 'cashbook_event.dart';
import 'cashbook_state.dart';

class CashbookBloc extends Bloc<CashbookEvent, CashbookState> {
  CashbookBloc({
    required this._getEntries,
    required this._syncCashbook,
  }) : super(const CashbookInitial()) {
    on<LoadCashbook>(_load);
    on<SyncCashbookRequested>(_sync);
  }

  final GetCashbookEntries _getEntries;
  final SyncCashbook _syncCashbook;

  Future<void> _load(LoadCashbook event, Emitter<CashbookState> emit) async {
    emit(const CashbookLoading());
    await _reload(emit);
  }

  Future<void> _sync(
    SyncCashbookRequested event,
    Emitter<CashbookState> emit,
  ) async {
    final current = state;
    if (current is CashbookLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }

    try {
      final result = await _syncCashbook(actorId: event.actorId);
      await _reload(emit, message: result.message);
    } catch (error) {
      if (current is CashbookLoaded) {
        emit(
          current.copyWith(
            isProcessing: false,
            error: _message(error),
            clearMessages: true,
          ),
        );
      } else {
        emit(CashbookFailure(_message(error)));
      }
    }
  }

  Future<void> _reload(Emitter<CashbookState> emit, {String? message}) async {
    try {
      emit(CashbookLoaded(entries: await _getEntries(), message: message));
    } catch (error) {
      emit(CashbookFailure(_message(error)));
    }
  }

  String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
