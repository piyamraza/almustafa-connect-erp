import '../entities/staff_leave_entity.dart';
import '../repositories/staff_leave_repository.dart';

class GetStaffLeavesByStaff {
  const GetStaffLeavesByStaff(this.repository);

  final StaffLeaveRepository repository;

  Future<List<StaffLeaveEntity>> call({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getLeavesByStaff(
      staffId: staffId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}