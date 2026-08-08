import 'package:equatable/equatable.dart';

import '../../domain/entities/payroll_profile_entity.dart';
import '../../domain/entities/payroll_record_entity.dart';
import '../../domain/entities/salary_history_entity.dart';

sealed class PayrollEvent extends Equatable {
  const PayrollEvent();

  @override
  List<Object?> get props => const [];
}

class LoadPayroll extends PayrollEvent {
  const LoadPayroll({this.actorId = ''});
  final String actorId;

  @override
  List<Object?> get props => [actorId];
}

class ApplySalaryIncrementsRequested extends PayrollEvent {
  const ApplySalaryIncrementsRequested({
    required this.increments,
    required this.actorId,
  });
  final List<SalaryIncrementRequest> increments;
  final String actorId;

  @override
  List<Object?> get props => [increments, actorId];
}

class SavePayrollProfileRequested extends PayrollEvent {
  const SavePayrollProfileRequested(this.profile);

  final PayrollProfileEntity profile;

  @override
  List<Object?> get props => [profile];
}

class SetPayrollProfileActiveRequested extends PayrollEvent {
  const SetPayrollProfileActiveRequested({
    required this.profileId,
    required this.isActive,
  });

  final String profileId;
  final bool isActive;

  @override
  List<Object?> get props => [profileId, isActive];
}

class DeletePayrollProfileRequested extends PayrollEvent {
  const DeletePayrollProfileRequested(this.profileId);

  final String profileId;

  @override
  List<Object?> get props => [profileId];
}

class GeneratePayrollRequested extends PayrollEvent {
  const GeneratePayrollRequested({required this.month, required this.actorId});

  final DateTime month;
  final String actorId;

  @override
  List<Object?> get props => [month, actorId];
}

class SavePayrollRecordRequested extends PayrollEvent {
  const SavePayrollRecordRequested(this.record);

  final PayrollRecordEntity record;

  @override
  List<Object?> get props => [record];
}

class UpdatePayrollStatusRequested extends PayrollEvent {
  const UpdatePayrollStatusRequested({
    required this.payrollId,
    required this.status,
    required this.actorId,
    this.paymentMethod = '',
    this.referenceNumber = '',
  });

  final String payrollId;
  final PayrollPaymentStatus status;
  final String actorId;
  final String paymentMethod;
  final String referenceNumber;

  @override
  List<Object?> get props => [
    payrollId,
    status,
    actorId,
    paymentMethod,
    referenceNumber,
  ];
}
