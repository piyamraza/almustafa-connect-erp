import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceByDate {
  final AttendanceRepository repository;

  GetAttendanceByDate(this.repository);

  Future<List<AttendanceEntity>> call(
    DateTime date,
  ) {
    return repository.getAttendanceByDate(
      date,
    );
  }
}