import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class UpdateAttendance {
  final AttendanceRepository repository;

  UpdateAttendance(this.repository);

  Future<void> call(
    AttendanceEntity attendance,
  ) {
    return repository.updateAttendance(attendance);
  }
}