import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_reference_resolver.dart';
import '../entities/attendance_entity.dart';
import '../entities/attendance_report.dart';
import '../repositories/attendance_repository.dart';

class GenerateAttendanceReport {
  GenerateAttendanceReport(this._repository, this._academicStructure);
  final AttendanceRepository _repository;
  final AcademicStructureRepository _academicStructure;

  Future<AttendanceReport> call(AttendanceReportFilter filter) async {
    final values = await Future.wait<Object>([
      _repository.getAttendanceForReport(
        fromDate: filter.fromDate,
        toDate: filter.toDate,
      ),
      _academicStructure.getClasses(),
      _academicStructure.getSections(),
    ]);
    final resolver = AcademicReferenceResolver(
      classes: values[1] as List<AcademicClassEntity>,
      sections: values[2] as List<SectionEntity>,
    );
    final source = (values[0] as List<AttendanceEntity>)
        .map(
          (record) => record.copyWith(
            classId: resolver.className(record.classId),
            sectionId: resolver.sectionName(record.sectionId),
          ),
        )
        .toList(growable: false);
    final records = source
        .where(
          (record) =>
              (filter.classId == null ||
                  resolver.sameClass(record.classId, filter.classId!)) &&
              (filter.sectionId == null ||
                  resolver.sameSection(record.sectionId, filter.sectionId!)) &&
              (filter.studentId == null ||
                  record.studentId == filter.studentId),
        )
        .toList();
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
      final dayKey =
          '${record.attendanceDate.year}-'
          '${record.attendanceDate.month.toString().padLeft(2, '0')}-'
          '${record.attendanceDate.day.toString().padLeft(2, '0')}';
      byDay.putIfAbsent(dayKey, () => []).add(record);
      final key = '${record.attendanceDate.year}-${record.attendanceDate.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(record);
    }
    return AttendanceReport(
      filter: filter,
      records: records,
      statistics: _statistics(records),
      studentStatistics: {
        for (final item in byStudent.entries)
          item.key: _statistics(item.value),
      },
      classStatistics: {
        for (final item in byClass.entries) item.key: _statistics(item.value),
      },
      sectionStatistics: {
        for (final item in bySection.entries)
          item.key: _statistics(item.value),
      },
      dailyStatistics: {
        for (final item in byDay.entries) item.key: _statistics(item.value),
      },
      monthlyTrend: {
        for (final item in byMonth.entries)
          item.key: _statistics(item.value).percentage,
      },
    );
  }

  AttendanceStatistics _statistics(List<AttendanceEntity> records) {
    int count(AttendanceStatus status) =>
        records.where((record) => record.status == status).length;
    final days = records
        .map(
          (record) => DateTime(
            record.attendanceDate.year,
            record.attendanceDate.month,
            record.attendanceDate.day,
          ),
        )
        .toSet()
        .length;
    return AttendanceStatistics(
      present: count(AttendanceStatus.present),
      absent: count(AttendanceStatus.absent),
      late: count(AttendanceStatus.late),
      leave: count(AttendanceStatus.leave),
      workingDays: days,
    );
  }
}
