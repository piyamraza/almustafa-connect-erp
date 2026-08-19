import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../attendance/domain/usecases/get_attendance_by_student.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/domain/repositories/exam_result_repository.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/usecases/get_student_by_id.dart';
import '../../domain/repositories/student_development_profile_repository.dart';
import '../../domain/entities/student_development_profile_entity.dart';
import '../../domain/services/result_card_insight_service.dart';
import 'report_card_event.dart';
import 'report_card_state.dart';

class ReportCardBloc extends Bloc<ReportCardEvent, ReportCardState> {
  ReportCardBloc({
    required this._getStudentById,
    required this._getAttendanceByStudent,
    required this.developmentProfileRepository,
    required this.examResultRepository,
  }) : super(const ReportCardInitial()) {
    on<LoadReportCard>(_onLoad);
  }

  final GetStudentById _getStudentById;
  final GetAttendanceByStudent _getAttendanceByStudent;
  final StudentDevelopmentProfileRepository developmentProfileRepository;
  final ExamResultRepository examResultRepository;
  static const _insights = ResultCardInsightService();

  Future<void> _onLoad(
    LoadReportCard event,
    Emitter<ReportCardState> emit,
  ) async {
    emit(ReportCardLoading(event.result));
    try {
      StudentEntity? student;
      List<AttendanceEntity> attendance = const [];
      List<ExamResultEntity> examResults = const [];
      List<ExamResultEntity> studentResults = const [];
      StudentDevelopmentProfileEntity? profile;
      try {
        profile = await developmentProfileRepository.getForStudent(
          examId: event.result.examId,
          studentId: event.result.studentId,
        );
        profile ??= await developmentProfileRepository
            .getLatestForStudentSession(
              studentId: event.result.studentId,
              academicSession: event.result.academicSession,
            );
      } catch (_) {
        // Older deployments remain printable before the new collection/rules
        // are deployed.
      }
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
      try {
        examResults = await examResultRepository.getResultsForExam(
          event.result.examId,
        );
        studentResults = await examResultRepository.getPublishedResults(
          studentId: event.result.studentId,
        );
      } catch (_) {
        // Comparison data is optional for migrated result records.
      }
      final attendancePercentage = _attendancePercentage(attendance);
      final peers = examResults
          .where(
            (item) =>
                item.classId == event.result.classId &&
                item.sectionId == event.result.sectionId,
          )
          .toList();
      final classAverage = peers.isEmpty
          ? null
          : peers.fold<double>(0, (sum, item) => sum + item.percentage) /
                peers.length;
      final highestPercentage = peers.isEmpty
          ? null
          : peers
                .map((item) => item.percentage)
                .reduce((a, b) => a > b ? a : b);
      studentResults.sort(
        (a, b) => (a.publishedAt ?? a.updatedAt).compareTo(
          b.publishedAt ?? b.updatedAt,
        ),
      );
      emit(
        ReportCardLoaded(
          result: event.result,
          student: student,
          attendancePercentage: attendancePercentage,
          attendanceDays: attendance.length,
          attendedDays: attendance
              .where(
                (record) =>
                    record.status == AttendanceStatus.present ||
                    record.status == AttendanceStatus.late,
              )
              .length,
          punctualityRating: _insights.punctualityRating(attendancePercentage),
          developmentProfile: profile,
          classAverage: classAverage,
          highestPercentage: highestPercentage,
          termProgress: [
            for (final item in studentResults)
              '${item.examName}: ${item.percentage.toStringAsFixed(1)}%',
          ],
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
    final attended = records
        .where(
          (record) =>
              record.status == AttendanceStatus.present ||
              record.status == AttendanceStatus.late,
        )
        .length;
    return (attended / records.length) * 100;
  }
}
