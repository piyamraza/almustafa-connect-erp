import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_payroll.dart';
import 'payroll_event.dart';
import 'payroll_state.dart';

class PayrollBloc extends Bloc<PayrollEvent, PayrollState> {
  PayrollBloc({
    required this._getData,
    required this._saveProfile,
    required this._generatePayroll,
    required this._saveRecord,
    required this._updateStatus,
  }) : super(const PayrollInitial()) {
    on<LoadPayroll>(_load);
    on<SavePayrollProfileRequested>(_saveProfileRequested);
    on<GeneratePayrollRequested>(_generateRequested);
    on<SavePayrollRecordRequested>(_saveRecordRequested);
    on<UpdatePayrollStatusRequested>(_updateStatusRequested);
  }

  final GetPayrollManagementData _getData;
  final SavePayrollProfile _saveProfile;
  final GenerateMonthlyPayroll _generatePayroll;
  final SavePayrollRecord _saveRecord;
  final UpdatePayrollStatus _updateStatus;

  Future<void> _load(LoadPayroll event, Emitter<PayrollState> emit) async {
    emit(const PayrollLoading());
    await _reload(emit);
  }

  Future<void> _saveProfileRequested(
    SavePayrollProfileRequested event,
    Emitter<PayrollState> emit,
  ) async {
    await _execute(
      emit,
      () => _saveProfile(event.profile),
      'Salary profile saved.',
    );
  }

  Future<void> _generateRequested(
    GeneratePayrollRequested event,
    Emitter<PayrollState> emit,
  ) async {
    await _execute(
      emit,
      () => _generatePayroll(month: event.month, actorId: event.actorId),
      'Monthly payroll generated.',
    );
  }

  Future<void> _saveRecordRequested(
    SavePayrollRecordRequested event,
    Emitter<PayrollState> emit,
  ) async {
    await _execute(
      emit,
      () => _saveRecord(event.record),
      'Payroll record updated.',
    );
  }

  Future<void> _updateStatusRequested(
    UpdatePayrollStatusRequested event,
    Emitter<PayrollState> emit,
  ) async {
    await _execute(
      emit,
      () => _updateStatus(
        payrollId: event.payrollId,
        status: event.status,
        actorId: event.actorId,
        paymentMethod: event.paymentMethod,
        referenceNumber: event.referenceNumber,
      ),
      'Payroll status updated.',
    );
  }

  Future<void> _execute(
    Emitter<PayrollState> emit,
    Future<void> Function() action,
    String success,
  ) async {
    final current = state;
    if (current is PayrollLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }
    try {
      await action();
      await _reload(emit, message: success);
    } catch (error) {
      if (current is PayrollLoaded) {
        emit(
          current.copyWith(
            isProcessing: false,
            error: error.toString(),
            clearMessages: true,
          ),
        );
      } else {
        emit(PayrollFailure(error.toString()));
      }
    }
  }

  Future<void> _reload(Emitter<PayrollState> emit, {String? message}) async {
    try {
      final data = await _getData();
      emit(
        PayrollLoaded(
          profiles: data.profiles,
          records: data.records,
          message: message,
        ),
      );
    } catch (error) {
      emit(PayrollFailure(error.toString()));
    }
  }
}
