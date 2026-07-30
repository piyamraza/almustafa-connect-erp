import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance_report.dart';

sealed class AttendanceReportState extends Equatable { const AttendanceReportState(); @override List<Object?> get props => []; }
class AttendanceReportInitial extends AttendanceReportState { const AttendanceReportInitial(); }
class AttendanceReportLoading extends AttendanceReportState { const AttendanceReportLoading(); }
class AttendanceReportLoaded extends AttendanceReportState { const AttendanceReportLoaded(this.report); final AttendanceReport report; @override List<Object> get props => [report]; }
class AttendanceReportError extends AttendanceReportState { const AttendanceReportError(this.message); final String message; @override List<Object> get props => [message]; }
