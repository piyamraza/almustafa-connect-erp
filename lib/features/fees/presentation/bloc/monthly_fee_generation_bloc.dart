import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/monthly_fee_due_entity.dart';
import '../../domain/entities/monthly_fee_generation_entity.dart';
import '../../domain/repositories/monthly_fee_due_repository.dart';
import '../../domain/usecases/generate_monthly_fees.dart';

sealed class MonthlyFeeGenerationEvent {
  const MonthlyFeeGenerationEvent();
}

class LoadMonthlyFeeGenerationData extends MonthlyFeeGenerationEvent {
  const LoadMonthlyFeeGenerationData({
    required this.academicSession,
    required this.month,
    required this.year,
  });

  final String academicSession;
  final int month;
  final int year;
}

class GenerateMonthlyFeeDues extends MonthlyFeeGenerationEvent {
  const GenerateMonthlyFeeDues(this.request);

  final MonthlyFeeGenerationRequest request;
}

class DeleteGeneratedMonthlyDue extends MonthlyFeeGenerationEvent {
  const DeleteGeneratedMonthlyDue({
    required this.id,
    required this.academicSession,
    required this.month,
    required this.year,
  });

  final String id;
  final String academicSession;
  final int month;
  final int year;
}

sealed class MonthlyFeeGenerationState {
  const MonthlyFeeGenerationState();
}

class MonthlyFeeGenerationInitial extends MonthlyFeeGenerationState {
  const MonthlyFeeGenerationInitial();
}

class MonthlyFeeGenerationLoading extends MonthlyFeeGenerationState {
  const MonthlyFeeGenerationLoading();
}

class MonthlyFeeGenerationLoaded extends MonthlyFeeGenerationState {
  const MonthlyFeeGenerationLoaded({
    required this.dues,
    this.result,
    this.message,
  });

  final List<MonthlyFeeDueEntity> dues;
  final MonthlyFeeGenerationResult? result;
  final String? message;
}

class MonthlyFeeGenerationError extends MonthlyFeeGenerationState {
  const MonthlyFeeGenerationError(this.message);

  final String message;
}

class MonthlyFeeGenerationBloc
    extends Bloc<MonthlyFeeGenerationEvent, MonthlyFeeGenerationState> {
  MonthlyFeeGenerationBloc(this._generateMonthlyFees, this._dueRepository)
    : super(const MonthlyFeeGenerationInitial()) {
    on<LoadMonthlyFeeGenerationData>(_load);
    on<GenerateMonthlyFeeDues>(_generate);
    on<DeleteGeneratedMonthlyDue>(_delete);
  }

  final GenerateMonthlyFees _generateMonthlyFees;
  final MonthlyFeeDueRepository _dueRepository;

  Future<void> _load(
    LoadMonthlyFeeGenerationData event,
    Emitter<MonthlyFeeGenerationState> emit,
  ) async {
    emit(const MonthlyFeeGenerationLoading());
    try {
      final dues = await _dueRepository.getMonthlyDues(
        academicSession: event.academicSession,
        month: event.month,
        year: event.year,
      );
      emit(MonthlyFeeGenerationLoaded(dues: dues));
    } catch (error) {
      emit(MonthlyFeeGenerationError(_message(error)));
    }
  }

  Future<void> _generate(
    GenerateMonthlyFeeDues event,
    Emitter<MonthlyFeeGenerationState> emit,
  ) async {
    emit(const MonthlyFeeGenerationLoading());
    try {
      final result = await _generateMonthlyFees(event.request);
      final dues = await _dueRepository.getMonthlyDues(
        academicSession: event.request.academicSession,
        month: event.request.month,
        year: event.request.year,
      );
      emit(
        MonthlyFeeGenerationLoaded(
          dues: dues,
          result: result,
          message: 'Monthly fee generation completed.',
        ),
      );
    } catch (error) {
      emit(MonthlyFeeGenerationError(_message(error)));
    }
  }

  Future<void> _delete(
    DeleteGeneratedMonthlyDue event,
    Emitter<MonthlyFeeGenerationState> emit,
  ) async {
    emit(const MonthlyFeeGenerationLoading());
    try {
      await _dueRepository.deleteMonthlyDue(event.id);
      final dues = await _dueRepository.getMonthlyDues(
        academicSession: event.academicSession,
        month: event.month,
        year: event.year,
      );
      emit(
        MonthlyFeeGenerationLoaded(dues: dues, message: 'Monthly due deleted.'),
      );
    } catch (error) {
      emit(MonthlyFeeGenerationError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
