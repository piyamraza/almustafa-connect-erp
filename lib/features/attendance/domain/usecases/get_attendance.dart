import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class GetAttendance {
  final AttendanceRepository repository;

  GetAttendance(this.repository);

  Future<List<AttendanceEntity>> call() {
    return repository.getAttendance();
  }
}