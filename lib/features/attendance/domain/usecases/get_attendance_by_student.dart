import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceByStudent {
  final AttendanceRepository repository;

  GetAttendanceByStudent(this.repository);

  Future<List<AttendanceEntity>> call(
    String studentId,
  ) {
    return repository.getAttendanceByStudent(
      studentId,
    );
  }
}