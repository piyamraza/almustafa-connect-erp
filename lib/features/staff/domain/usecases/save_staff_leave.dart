import '../entities/staff_leave_entity.dart';
import '../repositories/staff_leave_repository.dart';

class SaveStaffLeave {
  const SaveStaffLeave(this.repository);

  final StaffLeaveRepository repository;

  Future<void> call(
    StaffLeaveEntity leave,
  ) {
    return repository.saveLeave(leave);
  }
}