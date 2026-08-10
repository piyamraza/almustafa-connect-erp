import '../entities/class_timetable_entry_entity.dart';
import '../entities/teacher_workload_entity.dart';
import '../entities/timetable_report_entity.dart';
import '../repositories/timetable_repository.dart';
import 'get_teacher_workloads.dart';

class GenerateTimetableReport {
  const GenerateTimetableReport(
    this._timetableRepository,
    this._getTeacherWorkloads,
  );

  final TimetableRepository _timetableRepository;
  final GetTeacherWorkloads _getTeacherWorkloads;

  Future<TimetableReportEntity> call(
    TimetableReportRequestEntity request,
  ) async {
    final errors = request.validationErrors;
    if (errors.isNotEmpty) {
      throw ArgumentError(errors.first);
    }

    if (request.type == TimetableReportType.teacherWorkload) {
      final workloadReport = await _getTeacherWorkloads(
        branchId: request.branchId,
        academicSession: request.academicSession,
      );
      final configuration = workloadReport.configuration;
      if (configuration == null) {
        throw StateError(
          'Timetable configuration was not found for this branch and session.',
        );
      }

      return TimetableReportEntity(
        request: request,
        configuration: configuration,
        entries: const <ClassTimetableEntryEntity>[],
        workloads: workloadReport.workloads,
        generatedAt: DateTime.now(),
      );
    }

    final configuration = await _timetableRepository.getConfiguration(
      branchId: request.branchId,
      academicSession: request.academicSession,
      classId: request.type == TimetableReportType.classTimetable
          ? request.classId
          : null,
    );

    if (configuration == null) {
      throw StateError(
        'Timetable configuration was not found for this branch and session.',
      );
    }

    final entries = switch (request.type) {
      TimetableReportType.classTimetable =>
        await _timetableRepository.getClassTimetable(
          branchId: request.branchId,
          academicSession: request.academicSession,
          classId: request.classId!,
          sectionId: request.sectionId!,
        ),
      TimetableReportType.teacherTimetable =>
        await _timetableRepository.getTeacherTimetable(
          branchId: request.branchId,
          academicSession: request.academicSession,
          teacherId: request.teacherId!,
        ),
      TimetableReportType.teacherWorkload =>
        const <ClassTimetableEntryEntity>[],
    };

    return TimetableReportEntity(
      request: request,
      configuration: configuration,
      entries: entries,
      workloads: const <TeacherWorkloadEntity>[],
      generatedAt: DateTime.now(),
    );
  }
}
