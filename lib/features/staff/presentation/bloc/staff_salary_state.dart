import 'package:equatable/equatable.dart';

import '../../domain/entities/staff_salary_entity.dart';

sealed class StaffSalaryState extends Equatable {
  const StaffSalaryState();

  @override
  List<Object?> get props => [];
}

class StaffSalaryInitial extends StaffSalaryState {
  const StaffSalaryInitial();
}

class StaffSalaryLoading extends StaffSalaryState {
  const StaffSalaryLoading();
}

class StaffSalaryLoaded extends StaffSalaryState {
  const StaffSalaryLoaded({
    required this.salaries,
    this.selectedMonth,
    this.staffId,
    this.startDate,
    this.endDate,
    this.successMessage,
  });

  final List<StaffSalaryEntity> salaries;
  final DateTime? selectedMonth;
  final String? staffId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? successMessage;

  StaffSalaryLoaded copyWith({
    List<StaffSalaryEntity>? salaries,
    DateTime? selectedMonth,
    String? staffId,
    DateTime? startDate,
    DateTime? endDate,
    String? successMessage,
    bool clearSelectedMonth = false,
    bool clearStaffId = false,
    bool clearDateRange = false,
    bool clearSuccessMessage = false,
  }) {
    return StaffSalaryLoaded(
      salaries: salaries ?? this.salaries,
      selectedMonth:
          clearSelectedMonth
              ? null
              : selectedMonth ?? this.selectedMonth,
      staffId: clearStaffId ? null : staffId ?? this.staffId,
      startDate:
          clearDateRange ? null : startDate ?? this.startDate,
      endDate: clearDateRange ? null : endDate ?? this.endDate,
      successMessage: clearSuccessMessage
          ? null
          : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        salaries,
        selectedMonth,
        staffId,
        startDate,
        endDate,
        successMessage,
      ];
}

class StaffSalaryError extends StaffSalaryState {
  const StaffSalaryError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}