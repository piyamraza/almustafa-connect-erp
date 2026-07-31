import 'package:equatable/equatable.dart';

import '../../domain/entities/staff_leave_entity.dart';

sealed class StaffLeaveState extends Equatable {
  const StaffLeaveState();

  @override
  List<Object?> get props => [];
}

class StaffLeaveInitial extends StaffLeaveState {
  const StaffLeaveInitial();
}

class StaffLeaveLoading extends StaffLeaveState {
  const StaffLeaveLoading();
}

class StaffLeaveLoaded extends StaffLeaveState {
  const StaffLeaveLoaded({
    required this.leaves,
    this.staffId,
    this.startDate,
    this.endDate,
    this.pendingOnly = false,
    this.successMessage,
  });

  final List<StaffLeaveEntity> leaves;
  final String? staffId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool pendingOnly;
  final String? successMessage;

  @override
  List<Object?> get props => [
        leaves,
        staffId,
        startDate,
        endDate,
        pendingOnly,
        successMessage,
      ];
}

class StaffLeaveError extends StaffLeaveState {
  const StaffLeaveError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}