import '../entities/staff_attendance_entity.dart';
import '../repositories/staff_attendance_repository.dart';

class GetStaffAttendanceByDate {
  const GetStaffAttendanceByDate(this.repository);

  final StaffAttendanceRepository repository;

  Future<List<StaffAttendanceEntity>> call(
    DateTime date,
  ) {
    return repository.getAttendanceByDate(date);
  }
}