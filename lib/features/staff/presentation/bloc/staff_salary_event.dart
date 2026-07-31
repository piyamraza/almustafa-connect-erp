import 'package:equatable/equatable.dart';

import '../../domain/entities/staff_salary_entity.dart';

sealed class StaffSalaryEvent extends Equatable {
  const StaffSalaryEvent();

  @override
  List<Object?> get props => [];
}

class LoadStaffSalariesByMonthEvent extends StaffSalaryEvent {
  const LoadStaffSalariesByMonthEvent(this.month);

  final DateTime month;

  @override
  List<Object> get props => [month];
}

class GenerateStaffMonthlySalariesEvent
    extends StaffSalaryEvent {
  const GenerateStaffMonthlySalariesEvent(this.month);

  final DateTime month;

  @override
  List<Object> get props => [month];
}

class LoadStaffSalaryHistoryEvent extends StaffSalaryEvent {
  const LoadStaffSalaryHistoryEvent({
    required this.staffId,
    required this.startDate,
    required this.endDate,
  });

  final String staffId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object> get props => [
        staffId,
        startDate,
        endDate,
      ];
}

class SaveStaffSalaryAdjustmentsEvent
    extends StaffSalaryEvent {
  const SaveStaffSalaryAdjustmentsEvent(
    this.salary,
  );

  final StaffSalaryEntity salary;

  @override
  List<Object> get props => [salary];
}

class UpdateStaffSalaryPaymentStatusEvent
    extends StaffSalaryEvent {
  const UpdateStaffSalaryPaymentStatusEvent({
    required this.salaryId,
    required this.salaryMonth,
    required this.paymentStatus,
    required this.paymentDate,
    required this.paymentMethod,
    required this.paymentReference,
  });

  final String salaryId;
  final DateTime salaryMonth;
  final StaffSalaryPaymentStatus paymentStatus;
  final DateTime? paymentDate;
  final StaffSalaryPaymentMethod? paymentMethod;
  final String paymentReference;

  @override
  List<Object?> get props => [
        salaryId,
        salaryMonth,
        paymentStatus,
        paymentDate,
        paymentMethod,
        paymentReference,
      ];
}