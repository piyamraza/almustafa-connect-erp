import 'package:equatable/equatable.dart';

import '../../domain/entities/staff_leave_entity.dart';

sealed class StaffLeaveEvent extends Equatable {
  const StaffLeaveEvent();

  @override
  List<Object?> get props => [];
}

class LoadStaffLeavesByDateRangeEvent
    extends StaffLeaveEvent {
  const LoadStaffLeavesByDateRangeEvent({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object> get props => [
        startDate,
        endDate,
      ];
}

class LoadStaffLeaveHistoryEvent extends StaffLeaveEvent {
  const LoadStaffLeaveHistoryEvent({
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

class LoadPendingStaffLeavesEvent
    extends StaffLeaveEvent {
  const LoadPendingStaffLeavesEvent();
}

class SaveStaffLeaveEvent extends StaffLeaveEvent {
  const SaveStaffLeaveEvent(this.leave);

  final StaffLeaveEntity leave;

  @override
  List<Object> get props => [leave];
}

class DeleteStaffLeaveEvent extends StaffLeaveEvent {
  const DeleteStaffLeaveEvent(this.leaveId);

  final String leaveId;

  @override
  List<Object> get props => [leaveId];
}

class UpdateStaffLeaveStatusEvent
    extends StaffLeaveEvent {
  const UpdateStaffLeaveStatusEvent({
    required this.leave,
    required this.status,
    required this.approvalRemarks,
    required this.approvedBy,
  });

  final StaffLeaveEntity leave;
  final StaffLeaveStatus status;
  final String approvalRemarks;
  final String approvedBy;

  @override
  List<Object> get props => [
        leave,
        status,
        approvalRemarks,
        approvedBy,
      ];
}