import '../entities/attendance_entity.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceEntity>> getAttendance();

  Future<void> addAttendance(
    AttendanceEntity attendance,
  );

  Future<void> updateAttendance(
    AttendanceEntity attendance,
  );

  Future<void> deleteAttendance(
    String attendanceId,
  );

  Future<List<AttendanceEntity>> getAttendanceByDate(
    DateTime date,
  );

  Future<List<AttendanceEntity>> getAttendanceByStudent(
    String studentId,
  );

  Future<List<AttendanceEntity>> getAttendanceForReport({
    required DateTime fromDate,
    required DateTime toDate,
  });

  String generateAttendanceId();
}
