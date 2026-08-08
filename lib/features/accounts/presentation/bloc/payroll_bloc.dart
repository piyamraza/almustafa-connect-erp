import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_payroll.dart';
import 'payroll_event.dart';
import 'payroll_state.dart';

class PayrollBloc extends Bloc<PayrollEvent, PayrollState> {
  PayrollBloc({
    required this._getData,
    required this._saveProfile,
    required this._setProfileActive,
    required this._deleteProfile,
    required this._generatePayroll,
    required this._saveRecord,
    required this._updateStatus,
    required this._applyIncrements,
    required this._initializePayroll,
  }) : super(const PayrollInitial()) {
    on<LoadPayroll>(_load);
    on<SavePayrollProfileRequested>(_saveProfileRequested);
    on<SetPayrollProfileActiveRequested>(_setProfileActiveRequested);
    on<DeletePayrollProfileRequested>(_deleteProfileRequested);
    on<GeneratePayrollRequested>(_generateRequested);
    on<SavePayrollRecordRequested>(_saveRecordRequested);
    on<UpdatePayrollStatusRequested>(_updateStatusRequested);
    on<ApplySalaryIncrementsRequested>(_applyIncrementsRequested);
  }

  final GetPayrollManagementData _getData;
  final SavePayrollProfile _saveProfile;
  final SetPayrollProfileActive _setProfileActive;
  final DeletePayrollProfile _deleteProfile;
  final GenerateMonthlyPayroll _generatePayroll;
  final SavePayrollRecord _saveRecord;
  final UpdatePayrollStatus _updateStatus;
  final ApplySalaryIncrements _applyIncrements;
  final InitializeProfileBasedPayroll _initializePayroll;

  Future<void> _load(LoadPayroll event, Emitter<PayrollState> emit) async {
    emit(const PayrollLoading());
    try {
      if (event.actorId.isNotEmpty) {
        await _initializePayroll(event.actorId);
      }
      await _reload(emit);
    } catch (error) {
      emit(PayrollFailure(error.toString()));
    }
  }

  Future<void> _applyIncrementsRequested(
    ApplySalaryIncrementsRequested event,
    Emitter<PayrollState> emit,
  ) async {
    await _execute(
      emit,
      () => _applyIncrements(
        increments: event.increments,
        actorId: event.actorId,
      ),
      'Salary increments applied.',
    );
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

  Future<void> _setProfileActiveRequested(
    SetPayrollProfileActiveRequested event,
    Emitter<PayrollState> emit,
  ) async {
    await _execute(
      emit,
      () => _setProfileActive(
        profileId: event.profileId,
        isActive: event.isActive,
      ),
      event.isActive
          ? 'Salary profile activated.'
          : 'Salary profile deactivated.',
    );
  }

  Future<void> _deleteProfileRequested(
    DeletePayrollProfileRequested event,
    Emitter<PayrollState> emit,
  ) async {
    await _execute(
      emit,
      () => _deleteProfile(event.profileId),
      'Salary profile deleted.',
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
          employees: data.employees,
          salaryHistory: data.salaryHistory,
          message: message,
        ),
      );
    } catch (error) {
      emit(PayrollFailure(error.toString()));
    }
  }
}
