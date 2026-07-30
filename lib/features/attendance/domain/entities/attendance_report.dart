import 'package:equatable/equatable.dart';

import 'attendance_entity.dart';

enum AttendanceReportType { daily, monthly, dateRange, classWise, sectionWise, studentWise }

class AttendanceReportFilter extends Equatable {
  const AttendanceReportFilter({
    required this.type,
    required this.fromDate,
    required this.toDate,
    this.classId,
    this.sectionId,
    this.studentId,
  });

  final AttendanceReportType type;
  final DateTime fromDate;
  final DateTime toDate;
  final String? classId;
  final String? sectionId;
  final String? studentId;

  @override
  List<Object?> get props => [type, fromDate, toDate, classId, sectionId, studentId];
}

class AttendanceStatistics extends Equatable {
  const AttendanceStatistics({
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
    required this.workingDays,
  });
  final int present;
  final int absent;
  final int late;
  final int leave;
  final int workingDays;
  int get total => present + absent + late + leave;
  double get percentage => total == 0 ? 0 : ((present + late) / total) * 100;
  @override
  List<Object> get props => [present, absent, late, leave, workingDays];
}

class AttendanceReport extends Equatable {
  const AttendanceReport({
    required this.filter,
    required this.records,
    required this.statistics,
    required this.studentStatistics,
    required this.classStatistics,
    required this.sectionStatistics,
    required this.dailyStatistics,
    required this.monthlyTrend,
  });
  final AttendanceReportFilter filter;
  final List<AttendanceEntity> records;
  final AttendanceStatistics statistics;
  final Map<String, AttendanceStatistics> studentStatistics;
  final Map<String, AttendanceStatistics> classStatistics;
  final Map<String, AttendanceStatistics> sectionStatistics;
  final Map<String, AttendanceStatistics> dailyStatistics;
  final Map<String, double> monthlyTrend;
  @override
  List<Object> get props => [filter, records, statistics, studentStatistics, classStatistics, sectionStatistics, dailyStatistics, monthlyTrend];
}
