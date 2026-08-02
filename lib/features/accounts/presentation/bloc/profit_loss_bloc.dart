import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_profit_loss.dart';
import 'profit_loss_event.dart';
import 'profit_loss_state.dart';

class ProfitLossBloc extends Bloc<ProfitLossEvent, ProfitLossState> {
  ProfitLossBloc({
    required GetProfitLossSnapshots getSnapshots,
    required GenerateMonthlyProfitLoss generateMonthly,
  }) : _getSnapshots = getSnapshots,
       _generateMonthly = generateMonthly,
       super(const ProfitLossInitial()) {
    on<LoadProfitLoss>(_load);
    on<GenerateProfitLossRequested>(_generate);
  }

  final GetProfitLossSnapshots _getSnapshots;
  final GenerateMonthlyProfitLoss _generateMonthly;

  Future<void> _load(
    LoadProfitLoss event,
    Emitter<ProfitLossState> emit,
  ) async {
    emit(const ProfitLossLoading());
    await _reload(emit);
  }

  Future<void> _generate(
    GenerateProfitLossRequested event,
    Emitter<ProfitLossState> emit,
  ) async {
    final current = state;
    if (current is ProfitLossLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }

    try {
      await _generateMonthly(month: event.month, actorId: event.actorId);
      await _reload(emit, message: 'Monthly profit and loss generated.');
    } catch (error) {
      if (current is ProfitLossLoaded) {
        emit(
          current.copyWith(
            isProcessing: false,
            error: _message(error),
            clearMessages: true,
          ),
        );
      } else {
        emit(ProfitLossFailure(_message(error)));
      }
    }
  }

  Future<void> _reload(Emitter<ProfitLossState> emit, {String? message}) async {
    try {
      final snapshots = await _getSnapshots();
      emit(ProfitLossLoaded(snapshots: snapshots, message: message));
    } catch (error) {
      emit(ProfitLossFailure(_message(error)));
    }
  }

  String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
