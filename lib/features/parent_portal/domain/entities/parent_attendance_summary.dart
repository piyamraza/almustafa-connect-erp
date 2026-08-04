import '../../../attendance/domain/entities/attendance_entity.dart';

class ParentAttendanceSummary {
  const ParentAttendanceSummary({
    required this.records,
    required this.total,
    required this.present,
    required this.absent,
    required this.leave,
    required this.late,
  });

  final List<AttendanceEntity> records;
  final int total;
  final int present;
  final int absent;
  final int leave;
  final int late;

  double get attendancePercentage {
    if (total == 0) return 0;
    return ((present + late) / total) * 100;
  }
}
