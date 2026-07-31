import '../../domain/entities/staff_leave_entity.dart';
import '../../domain/repositories/staff_leave_repository.dart';
import '../datasources/staff_leave_remote_datasource.dart';
import '../models/staff_leave_model.dart';

class StaffLeaveRepositoryImpl
    implements StaffLeaveRepository {
  const StaffLeaveRepositoryImpl(
    this._remoteDataSource,
  );

  final StaffLeaveRemoteDataSource _remoteDataSource;

  @override
  Future<List<StaffLeaveEntity>> getLeavesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _remoteDataSource.getLeavesByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<StaffLeaveEntity>> getLeavesByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _remoteDataSource.getLeavesByStaff(
      staffId: staffId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<StaffLeaveEntity>> getPendingLeaves() {
    return _remoteDataSource.getPendingLeaves();
  }

  @override
  Future<void> saveLeave(
    StaffLeaveEntity leave,
  ) {
    return _remoteDataSource.saveLeave(
      StaffLeaveModel.fromEntity(leave),
    );
  }

  @override
  Future<void> deleteLeave(
    String leaveId,
  ) {
    return _remoteDataSource.deleteLeave(leaveId);
  }

  @override
  Future<void> updateLeaveStatus({
    required String leaveId,
    required StaffLeaveStatus status,
    required String approvalRemarks,
    required String approvedBy,
    required DateTime? approvedAt,
    required DateTime updatedAt,
  }) {
    return _remoteDataSource.updateLeaveStatus(
      leaveId: leaveId,
      status: status,
      approvalRemarks: approvalRemarks,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      updatedAt: updatedAt,
    );
  }
}