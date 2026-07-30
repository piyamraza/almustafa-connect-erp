import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/generate_attendance_report.dart';
import 'attendance_report_event.dart';
import 'attendance_report_state.dart';

class AttendanceReportBloc extends Bloc<AttendanceReportEvent, AttendanceReportState> {
  AttendanceReportBloc(this._generateReport) : super(const AttendanceReportInitial()) {
    on<GenerateAttendanceReportEvent>(_onGenerate);
  }
  final GenerateAttendanceReport _generateReport;
  Future<void> _onGenerate(GenerateAttendanceReportEvent event, Emitter<AttendanceReportState> emit) async {
    emit(const AttendanceReportLoading());
    try { emit(AttendanceReportLoaded(await _generateReport(event.filter))); }
    catch (error) { emit(AttendanceReportError(error.toString())); }
  }
}
