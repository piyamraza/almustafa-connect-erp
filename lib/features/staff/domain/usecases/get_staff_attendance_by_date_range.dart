import '../entities/staff_attendance_entity.dart';
import '../repositories/staff_attendance_repository.dart';

class GetStaffAttendanceByDateRange {
  const GetStaffAttendanceByDateRange(this.repository);

  final StaffAttendanceRepository repository;

  Future<List<StaffAttendanceEntity>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getAttendanceByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }
}