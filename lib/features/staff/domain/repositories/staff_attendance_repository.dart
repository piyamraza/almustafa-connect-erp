import '../entities/staff_attendance_entity.dart';

abstract class StaffAttendanceRepository {
  Future<List<StaffAttendanceEntity>> getAttendanceByDate(
    DateTime date,
  );

  Future<List<StaffAttendanceEntity>> getAttendanceByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<StaffAttendanceEntity>> getAttendanceByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> saveAttendance(
    StaffAttendanceEntity attendance,
  );
}