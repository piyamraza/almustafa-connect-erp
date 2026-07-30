import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance_report.dart';

sealed class AttendanceReportEvent extends Equatable {
  const AttendanceReportEvent();
  @override List<Object?> get props => [];
}
class GenerateAttendanceReportEvent extends AttendanceReportEvent {
  const GenerateAttendanceReportEvent(this.filter);
  final AttendanceReportFilter filter;
  @override List<Object?> get props => [filter];
}
