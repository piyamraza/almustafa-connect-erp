import '../entities/staff_leave_entity.dart';
import '../repositories/staff_leave_repository.dart';

class GetPendingStaffLeaves {
  const GetPendingStaffLeaves(this.repository);

  final StaffLeaveRepository repository;

  Future<List<StaffLeaveEntity>> call() {
    return repository.getPendingLeaves();
  }
}