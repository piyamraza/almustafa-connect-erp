import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../domain/entities/parent_attendance_summary.dart';
import '../../domain/services/parent_attendance_service.dart';

class ParentAttendanceServiceImpl implements ParentAttendanceService {
  const ParentAttendanceServiceImpl(this._repository);

  final AttendanceRepository _repository;

  @override
  Future<ParentAttendanceSummary> loadMonthlyAttendance({
    required String studentId,
    required int year,
    required int month,
  }) {
    final fromDate = DateTime(year, month, 1);
    final toDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return loadAttendanceRange(
      studentId: studentId,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  @override
  Future<ParentAttendanceSummary> loadAttendanceRange({
    required String studentId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final values = await _repository.getAttendanceByStudent(studentId.trim());

    final records =
        values
            .where(
              (record) =>
                  !record.attendanceDate.isBefore(fromDate) &&
                  !record.attendanceDate.isAfter(toDate),
            )
            .toList()
          ..sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));

    var present = 0;
    var absent = 0;
    var leave = 0;
    var late = 0;

    for (final record in records) {
      switch (record.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.leave:
          leave++;
          break;
        case AttendanceStatus.late:
          late++;
          break;
      }
    }

    return ParentAttendanceSummary(
      records: List<AttendanceEntity>.unmodifiable(records),
      total: records.length,
      present: present,
      absent: absent,
      leave: leave,
      late: late,
    );
  }
}
