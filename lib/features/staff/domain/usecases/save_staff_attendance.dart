import '../entities/staff_attendance_entity.dart';
import '../repositories/staff_attendance_repository.dart';

class SaveStaffAttendance {
  const SaveStaffAttendance(this.repository);

  final StaffAttendanceRepository repository;

  Future<void> call(
    StaffAttendanceEntity attendance,
  ) {
    return repository.saveAttendance(attendance);
  }
}