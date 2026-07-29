import '../repositories/attendance_repository.dart';

class DeleteAttendance {
  final AttendanceRepository repository;

  DeleteAttendance(this.repository);

  Future<void> call(
    String attendanceId,
  ) {
    return repository.deleteAttendance(
      attendanceId,
    );
  }
}