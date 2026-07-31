import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../attendance/domain/usecases/get_attendance_by_student.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/usecases/get_student_by_id.dart';
import 'report_card_event.dart';
import 'report_card_state.dart';

class ReportCardBloc extends Bloc<ReportCardEvent, ReportCardState> {
  ReportCardBloc({
    required this._getStudentById,
    required this._getAttendanceByStudent,
  })  : super(const ReportCardInitial()) {
    on<LoadReportCard>(_onLoad);
  }

  final GetStudentById _getStudentById;
  final GetAttendanceByStudent _getAttendanceByStudent;

  Future<void> _onLoad(
    LoadReportCard event,
    Emitter<ReportCardState> emit,
  ) async {
    emit(ReportCardLoading(event.result));
    try {
      StudentEntity? student;
      List<AttendanceEntity> attendance = const [];
      try {
        student = await _getStudentById(event.result.studentId);
      } catch (_) {
        // A report card remains usable when an older result has no profile.
      }
      try {
        attendance = await _getAttendanceByStudent(event.result.studentId);
      } catch (_) {
        // Attendance is optional on a result card.
      }
      emit(
        ReportCardLoaded(
          result: event.result,
          student: student,
          attendancePercentage: _attendancePercentage(attendance),
        ),
      );
    } catch (error) {
      emit(
        ReportCardFailure(
          result: event.result,
          message: error
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('StateError: ', ''),
        ),
      );
    }
  }

  double? _attendancePercentage(List<AttendanceEntity> records) {
    if (records.isEmpty) return null;
    final attended = records.where(
      (record) =>
          record.status == AttendanceStatus.present ||
          record.status == AttendanceStatus.late,
    ).length;
    return (attended / records.length) * 100;
  }
}
