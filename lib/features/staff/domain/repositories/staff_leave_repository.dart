import '../entities/staff_leave_entity.dart';

abstract class StaffLeaveRepository {
  Future<List<StaffLeaveEntity>> getLeavesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<StaffLeaveEntity>> getLeavesByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<StaffLeaveEntity>> getPendingLeaves();

  Future<void> saveLeave(
    StaffLeaveEntity leave,
  );

  Future<void> deleteLeave(
    String leaveId,
  );

  Future<void> updateLeaveStatus({
    required String leaveId,
    required StaffLeaveStatus status,
    required String approvalRemarks,
    required String approvedBy,
    required DateTime? approvedAt,
    required DateTime updatedAt,
  });
}