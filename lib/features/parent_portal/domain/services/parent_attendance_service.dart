import '../entities/parent_attendance_summary.dart';

abstract class ParentAttendanceService {
  Future<ParentAttendanceSummary> loadMonthlyAttendance({
    required String studentId,
    required int year,
    required int month,
  });

  Future<ParentAttendanceSummary> loadAttendanceRange({
    required String studentId,
    required DateTime fromDate,
    required DateTime toDate,
  });
}
