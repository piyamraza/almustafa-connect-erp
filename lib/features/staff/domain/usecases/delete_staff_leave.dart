import '../repositories/staff_leave_repository.dart';

class DeleteStaffLeave {
  const DeleteStaffLeave(this.repository);

  final StaffLeaveRepository repository;

  Future<void> call(
    String leaveId,
  ) {
    return repository.deleteLeave(leaveId);
  }
}