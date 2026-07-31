import '../entities/staff_attendance_entity.dart';
import '../repositories/staff_attendance_repository.dart';

class GetStaffAttendanceByStaff {
  const GetStaffAttendanceByStaff(this.repository);

  final StaffAttendanceRepository repository;

  Future<List<StaffAttendanceEntity>> call({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getAttendanceByStaff(
      staffId: staffId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}