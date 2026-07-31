import '../entities/staff_leave_entity.dart';
import '../repositories/staff_leave_repository.dart';

class GetStaffLeavesByDateRange {
  const GetStaffLeavesByDateRange(this.repository);

  final StaffLeaveRepository repository;

  Future<List<StaffLeaveEntity>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getLeavesByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }
}