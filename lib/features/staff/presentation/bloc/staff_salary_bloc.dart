import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/generate_staff_monthly_salaries.dart';
import '../../domain/usecases/get_staff_salaries_by_month.dart';
import '../../domain/usecases/get_staff_salary_by_staff.dart';
import '../../domain/usecases/save_staff_salary.dart';
import '../../domain/usecases/update_staff_salary_payment_status.dart';
import 'staff_salary_event.dart';
import 'staff_salary_state.dart';

class StaffSalaryBloc
    extends Bloc<StaffSalaryEvent, StaffSalaryState> {
  StaffSalaryBloc({
    required this._generateStaffMonthlySalaries,
    required GetStaffSalariesByMonth
        getStaffSalariesByMonth,
    required this._getStaffSalaryByStaff,
    required this._saveStaffSalary,
    required this._updateStaffSalaryPaymentStatus,
  })  : _getStaffSalariesByMonth =
            getStaffSalariesByMonth,
        super(const StaffSalaryInitial()) {
    on<LoadStaffSalariesByMonthEvent>(
      _onLoadStaffSalariesByMonth,
    );
    on<GenerateStaffMonthlySalariesEvent>(
      _onGenerateStaffMonthlySalaries,
    );
    on<LoadStaffSalaryHistoryEvent>(
      _onLoadStaffSalaryHistory,
    );
    on<SaveStaffSalaryAdjustmentsEvent>(
      _onSaveStaffSalaryAdjustments,
    );
    on<UpdateStaffSalaryPaymentStatusEvent>(
      _onUpdateStaffSalaryPaymentStatus,
    );
  }

  final GenerateStaffMonthlySalaries
      _generateStaffMonthlySalaries;
  final GetStaffSalariesByMonth
      _getStaffSalariesByMonth;
  final GetStaffSalaryByStaff
      _getStaffSalaryByStaff;
  final SaveStaffSalary _saveStaffSalary;
  final UpdateStaffSalaryPaymentStatus
      _updateStaffSalaryPaymentStatus;

  Future<void> _onLoadStaffSalariesByMonth(
    LoadStaffSalariesByMonthEvent event,
    Emitter<StaffSalaryState> emit,
  ) async {
    emit(const StaffSalaryLoading());

    try {
      final salaries =
          await _getStaffSalariesByMonth(event.month);

      emit(
        StaffSalaryLoaded(
          salaries: salaries,
          selectedMonth: DateTime(
            event.month.year,
            event.month.month,
          ),
        ),
      );
    } catch (error) {
      emit(
        StaffSalaryError(
          error.toString(),
        ),
      );
    }
  }

  Future<void> _onGenerateStaffMonthlySalaries(
    GenerateStaffMonthlySalariesEvent event,
    Emitter<StaffSalaryState> emit,
  ) async {
    emit(const StaffSalaryLoading());

    try {
      final salaries =
          await _generateStaffMonthlySalaries(event.month);

      emit(
        StaffSalaryLoaded(
          salaries: salaries,
          selectedMonth: DateTime(
            event.month.year,
            event.month.month,
          ),
          successMessage:
              'Monthly staff salaries generated successfully.',
        ),
      );
    } catch (error) {
      emit(
        StaffSalaryError(
          error.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadStaffSalaryHistory(
    LoadStaffSalaryHistoryEvent event,
    Emitter<StaffSalaryState> emit,
  ) async {
    emit(const StaffSalaryLoading());

    try {
      final salaries =
          await _getStaffSalaryByStaff(
        staffId: event.staffId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        StaffSalaryLoaded(
          salaries: salaries,
          staffId: event.staffId,
          startDate: event.startDate,
          endDate: event.endDate,
        ),
      );
    } catch (error) {
      emit(
        StaffSalaryError(
          error.toString(),
        ),
      );
    }
  }

  Future<void> _onSaveStaffSalaryAdjustments(
    SaveStaffSalaryAdjustmentsEvent event,
    Emitter<StaffSalaryState> emit,
  ) async {
    emit(const StaffSalaryLoading());

    try {
      await _saveStaffSalary(event.salary);

      final salaries =
          await _getStaffSalariesByMonth(
        event.salary.salaryMonth,
      );

      emit(
        StaffSalaryLoaded(
          salaries: salaries,
          selectedMonth: event.salary.salaryMonth,
          successMessage:
              'Salary adjustments saved successfully.',
        ),
      );
    } catch (error) {
      emit(
        StaffSalaryError(
          error.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateStaffSalaryPaymentStatus(
    UpdateStaffSalaryPaymentStatusEvent event,
    Emitter<StaffSalaryState> emit,
  ) async {
    emit(const StaffSalaryLoading());

    try {
      await _updateStaffSalaryPaymentStatus(
        salaryId: event.salaryId,
        paymentStatus: event.paymentStatus,
        paymentDate: event.paymentDate,
        paymentMethod: event.paymentMethod,
        paymentReference: event.paymentReference,
      );

      final salaries =
          await _getStaffSalariesByMonth(
        event.salaryMonth,
      );

      emit(
        StaffSalaryLoaded(
          salaries: salaries,
          selectedMonth: event.salaryMonth,
          successMessage:
              'Salary payment status updated successfully.',
        ),
      );
    } catch (error) {
      emit(
        StaffSalaryError(
          error.toString(),
        ),
      );
    }
  }
}