import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class AddAttendance {
  final AttendanceRepository repository;

  AddAttendance(this.repository);

  Future<void> call(
    AttendanceEntity attendance,
  ) {
    return repository.addAttendance(attendance);
  }
}