import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_income.dart';
import 'income_event.dart';
import 'income_state.dart';

class IncomeBloc extends Bloc<IncomeEvent, IncomeState> {
  IncomeBloc({
    required this._getIncomeEntries,
    required this._saveIncomeEntry,
    required this._reverseIncomeEntry,
    required this._syncFeePayments,
  }) : super(const IncomeInitial()) {
    on<LoadIncomeEntries>(_load);
    on<SaveIncomeEntryRequested>(_save);
    on<ReverseIncomeEntryRequested>(_reverse);
    on<SyncFeeIncomeRequested>(_sync);
  }

  final GetIncomeEntries _getIncomeEntries;
  final SaveIncomeEntry _saveIncomeEntry;
  final ReverseIncomeEntry _reverseIncomeEntry;
  final SyncFeePaymentsToIncome _syncFeePayments;

  Future<void> _load(LoadIncomeEntries event, Emitter<IncomeState> emit) async {
    emit(const IncomeLoading());
    await _reload(emit);
  }

  Future<void> _save(
    SaveIncomeEntryRequested event,
    Emitter<IncomeState> emit,
  ) async {
    await _execute(
      emit,
      () => _saveIncomeEntry(event.entry),
      'Income entry saved successfully.',
    );
  }

  Future<void> _reverse(
    ReverseIncomeEntryRequested event,
    Emitter<IncomeState> emit,
  ) async {
    await _execute(
      emit,
      () => _reverseIncomeEntry(
        incomeEntryId: event.incomeEntryId,
        reason: event.reason,
      ),
      'Income entry reversed successfully.',
    );
  }

  Future<void> _sync(
    SyncFeeIncomeRequested event,
    Emitter<IncomeState> emit,
  ) async {
    final current = state;
    if (current is IncomeLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }
    try {
      final result = await _syncFeePayments(
        actorId: event.actorId,
        academicSession: event.academicSession,
      );
      await _reload(emit, message: result.message);
    } catch (error) {
      if (current is IncomeLoaded) {
        emit(
          current.copyWith(
            isProcessing: false,
            error: _message(error),
            clearMessages: true,
          ),
        );
      } else {
        emit(IncomeFailure(_message(error)));
      }
    }
  }

  Future<void> _execute(
    Emitter<IncomeState> emit,
    Future<void> Function() action,
    String successMessage,
  ) async {
    final current = state;
    if (current is IncomeLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }
    try {
      await action();
      await _reload(emit, message: successMessage);
    } catch (error) {
      if (current is IncomeLoaded) {
        emit(
          current.copyWith(
            isProcessing: false,
            error: _message(error),
            clearMessages: true,
          ),
        );
      } else {
        emit(IncomeFailure(_message(error)));
      }
    }
  }

  Future<void> _reload(Emitter<IncomeState> emit, {String? message}) async {
    try {
      final entries = await _getIncomeEntries();
      emit(IncomeLoaded(entries: entries, message: message));
    } catch (error) {
      emit(IncomeFailure(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
