import '../entities/attendance_entity.dart';
import '../entities/attendance_report.dart';
import '../repositories/attendance_repository.dart';

class GenerateAttendanceReport {
  GenerateAttendanceReport(this._repository);
  final AttendanceRepository _repository;

  Future<AttendanceReport> call(AttendanceReportFilter filter) async {
    final source = await _repository.getAttendanceForReport(fromDate: filter.fromDate, toDate: filter.toDate);
    final records = source.where((record) =>
      (filter.classId == null || record.classId == filter.classId) &&
      (filter.sectionId == null || record.sectionId == filter.sectionId) &&
      (filter.studentId == null || record.studentId == filter.studentId)).toList();
    final byStudent = <String, List<AttendanceEntity>>{};
    final byClass = <String, List<AttendanceEntity>>{};
    final bySection = <String, List<AttendanceEntity>>{};
    final byDay = <String, List<AttendanceEntity>>{};
    final byMonth = <String, List<AttendanceEntity>>{};
    for (final record in records) {
      byStudent.putIfAbsent(record.studentId, () => []).add(record);
      byClass.putIfAbsent(record.classId, () => []).add(record);
      final sectionKey = '${record.classId} - ${record.sectionId}';
      bySection.putIfAbsent(sectionKey, () => []).add(record);
      final dayKey = '${record.attendanceDate.year}-${record.attendanceDate.month.toString().padLeft(2, '0')}-${record.attendanceDate.day.toString().padLeft(2, '0')}';
      byDay.putIfAbsent(dayKey, () => []).add(record);
      final key = '${record.attendanceDate.year}-${record.attendanceDate.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(record);
    }
    return AttendanceReport(
      filter: filter,
      records: records,
      statistics: _statistics(records),
      studentStatistics: {for (final item in byStudent.entries) item.key: _statistics(item.value)},
      classStatistics: {for (final item in byClass.entries) item.key: _statistics(item.value)},
      sectionStatistics: {for (final item in bySection.entries) item.key: _statistics(item.value)},
      dailyStatistics: {for (final item in byDay.entries) item.key: _statistics(item.value)},
      monthlyTrend: {for (final item in byMonth.entries) item.key: _statistics(item.value).percentage},
    );
  }

  AttendanceStatistics _statistics(List<AttendanceEntity> records) {
    int count(AttendanceStatus status) => records.where((r) => r.status == status).length;
    final days = records.map((r) => DateTime(r.attendanceDate.year, r.attendanceDate.month, r.attendanceDate.day)).toSet().length;
    return AttendanceStatistics(present: count(AttendanceStatus.present), absent: count(AttendanceStatus.absent), late: count(AttendanceStatus.late), leave: count(AttendanceStatus.leave), workingDays: days);
  }
}
